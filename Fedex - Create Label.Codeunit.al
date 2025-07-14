codeunit 50102 "Fedex - Create Label"
{
    TableNo = "Sales Shipment Header";
    Permissions = tabledata "Sales Shipment Header" = M;
    trigger OnRun()
    begin
        RefreshToken();
        Token := GetAccessToken();
        SetAuthorizationHeader(Token);
        RequestContent := SetContentHeaders(Rec);
        CreateDirectory(Rec);
        CallShipAPI();
        HandleCreationResponse(Response, Rec);
    end;

    local procedure CreateDirectory(ShipmentHdr: Record "Sales Shipment Header")
    var
        PrinterCreateDir: Codeunit "Printer - Create Directory";
        Exists: Boolean;
    begin
        PrinterCreateDir.SetSalesShipmentHeader(ShipmentHdr);
        PrinterCreateDir.Run();
    end;

    local procedure HandleCreationResponse(ResponseMsg: HttpResponseMessage; ShipmentHdr: Record "Sales Shipment Header")
    begin
        LabelCreationResponse.SetResponseData(ResponseMsg);
        LabelCreationResponse.SetShipmentHeader(ShipmentHdr);
        LabelCreationResponse.Run();
    end;

    local procedure CallShipAPI(): HttpResponseMessage
    var
        Path: Text;
        Endpoint: Text;
        IsSuccessful: Boolean;
    begin
        Path := GetURLPath();
        Endpoint := '/ship/v1/shipments';
        IsSuccessful := HttpClient.Post(Path + Endpoint, RequestContent, Response);
        if IsSuccessful then
            FedexHttpErrorHandler.HandleHttpError(Response);
    end;

    local procedure RefreshToken()
    var
        FedexAuthorization: Codeunit "Fedex Authorization";
    begin
        if not FedexSetup.Find('-') then
            exit;

        if CurrentDateTime() > FedexSetup.Token_Expiary then begin
            FedexAuthorization.SetHide(true);
            FedexAuthorization.Run();
        end;

    end;

    local procedure GetAccessToken(): Text
    var
        Token: Text;
    begin
        IsolatedStorage.Get('AccessToken', DataScope::Module, Token);
        exit(Token);
    end;

    local procedure SetAuthorizationHeader(Token: Text)
    begin
        HttpClient.DefaultRequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', Token));
    end;

    local procedure SetContentHeaders(var SalesShipmentHeader: Record "Sales Shipment Header"): HttpContent
    var
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetContentHeaders(Content, ContentHeaders, IsHandled);
        if IsHandled then
            exit(Content);

        Body := SetRequestBody(SalesShipmentHeader);
        Body.WriteTo(Payload);
        Content.WriteFrom(Payload);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');
        ContentHeaders.Add('X-locale', 'en_GB');
        OnAfterSetContentHeaders(Content, ContentHeaders);
        exit(Content);
    end;

    local procedure GetURLPath() Path: Text
    begin
        if not FedexSetup.Find('-') then
            exit;

        Path := FedexSetup.URI;
        exit(Path);
    end;

    local procedure SetRequestBody(var SalesShipmentHeader: Record "Sales Shipment Header"): JsonObject
    var
        CompanyInfo: Record "Company Information";
        PickUpTypEnum: Text;
        SequenceNumber: Integer;
        TotalPackageCount: Integer;
        RequestedShipmentObj: JsonObject;
        RequestedShipmentTokens: JsonObject;
        ShipperObj: JsonObject;
        RecipientObj: JsonArray;
        ShippingAgentServicesDescription: Text;
        ShippingChargesPaymentsObj: JsonObject;
        ShippingChargesPaymentsTokens: JsonObject;
        LabelSpecificationObj: JsonObject;
        RequestedPackageLineItemsArray: JsonArray;
        RequestedPackageLineItemsObj: JsonObject;
        RequestedPackageLineItemsTokens: JsonObject;
        CustomerReferenceArray: JsonArray;
        RateRequestType: JsonArray;
        Weight: JsonObject;
        AccountNumber: JsonObject;
    begin
        TotalPackageCount := 0;
        TotalWeight := 0;
        SequenceNumber := 1;
        if not FedexSetup.Find('-') then
            Error('Please complete Fedex Setup Page to continue.');
        ShipperObj := GetShipperJsonObject();
        RequestedShipmentTokens.Add('shipper', ShipperObj);
        RecipientObj := GetRecipientJsonArray(SalesShipmentHeader);
        RequestedShipmentTokens.Add('recipients', RecipientObj);
        PickUpTypEnum := GetPickUpType(FedexSetup.PickUpType);
        RequestedShipmentTokens.Add('pickupType', PickUpTypEnum);// Should this field appear on the Posted Sales Shipment?
        ShippingAgentServicesDescription := GetShippingAgentServicesDescription(SalesShipmentHeader);
        RequestedShipmentTokens.Add('serviceType', ShippingAgentServicesDescription);
        RequestedShipmentTokens.Add('packagingType', 'YOUR_PACKAGING');

        SalesShipmentLine.Reset();
        SalesShipmentLine.SetFilter("Order No.", SalesShipmentHeader."Order No.");
        SalesShipmentLine.SetFilter(Type, Format(SalesShipmentLine.Type::Item));
        SalesShipmentLine.FindSet();
        repeat
            TotalWeight += (SalesShipmentLine."Gross Weight" * SalesShipmentLine."Qty. Shipped Not Invoiced");
            TotalPackageCount += SalesShipmentLine."Qty. Shipped Not Invoiced";
            RequestedPackageLineItemsTokens.Add('sequenceNumber', Format(SequenceNumber));
            RequestedPackageLineItemsTokens.Add('subPackagingType', SalesShipmentLine."Unit of Measure Code");
            CustomerReferenceArray := GetCustomerReferenceValues(SalesShipmentHeader);
            RequestedPackageLineItemsTokens.Add('customerReferences', CustomerReferenceArray.AsToken());
            RequestedPackageLineItemsTokens.Add('groupPackageCount', GetGroupPackageCount(SalesShipmentLine));
            Weight.Add('units', 'KG');
            Weight.Add('value', SalesShipmentLine."Gross Weight");
            RequestedPackageLineItemsTokens.Add('weight', Weight.AsToken());
            RequestedPackageLineItemsTokens.Add('itemDescription', GetDescription(SalesShipmentLine));
            RequestedPackageLineItemsArray.Add(RequestedPackageLineItemsTokens);
            Clear(RequestedPackageLineItemsTokens);
            Clear(Weight);
            Clear(CustomerReferenceArray);
            SequenceNumber += 1;
        until SalesShipmentLine.Next <= 0;
        RequestedShipmentTokens.Add('totalWeight', TotalWeight);
        ShippingChargesPaymentsTokens.Add('paymentType', 'SENDER');
        RequestedShipmentTokens.Add('shippingChargesPayment', ShippingChargesPaymentsTokens.AsToken());
        LabelSpecificationObj := GetLabelSpecificationObject();
        RequestedShipmentTokens.Add('labelSpecification', LabelSpecificationObj);
        RateRequestType.Add('NONE');
        RequestedShipmentTokens.Add('rateRequestType', RateRequestType);
        RequestedShipmentTokens.Add('totalPackageCount', TotalPackageCount);
        RequestedShipmentTokens.Add('requestedPackageLineItems', RequestedPackageLineItemsArray);
        RequestedShipmentObj.Add('requestedShipment', RequestedShipmentTokens);
        RequestedShipmentObj.Add('labelResponseOptions', 'LABEL');
        AccountNumber := GetAccountNumber();
        RequestedShipmentObj.Add('accountNumber', AccountNumber);
        RequestedShipmentObj.Add('oneLabelAtATime', false);
        exit(RequestedShipmentObj);
    end;

    local procedure GetAccountNumber() AccountNumber: JsonObject
    begin
        AccountNumber.Add('value', FedexSetup.AccountNumber);
        exit(AccountNumber);
    end;

    local procedure GetDescription(var SalesShipmentLine: Record "Sales Shipment Line") Description: Text
    begin
        Description := Format(SalesShipmentLine.Description, 50);
        Description := Description.Replace(' ', '');
        exit(Description);
    end;

    local procedure GetShipperJsonObject() ShipperObj: JsonObject
    var
        ShipperAddObj: JsonObject;
        ShipperAddTokens: JsonObject;
        ShipperStreetLinesArray: JsonArray;
        ShipperContact: JsonObject;
        CompanyInfo: Record "Company Information";
    begin
        if not CompanyInfo.Find('-') then
            Error('Company Information not found');
        ShipperStreetLinesArray.Add(CompanyInfo."Ship-to Address");
        ShipperAddTokens.Add('streetLines', ShipperStreetLinesArray);
        ShipperAddTokens.Add('city', 'Luton');
        ShipperAddTokens.Add('postalCode', CompanyInfo."Ship-to Post Code");
        ShipperAddTokens.Add('countryCode', CompanyInfo."Ship-to Country/Region Code");
        ShipperAddTokens.Add('residential', false);
        ShipperContact.Add('personName', CompanyInfo."Ship-to Contact");
        ShipperContact.Add('phoneNumber', CompanyInfo."Ship-to Phone No.");
        ShipperObj.Add('address', ShipperAddTokens);
        ShipperObj.Add('contact', ShipperContact);
        exit(ShipperObj);
    end;

    local procedure GetRecipientJsonArray(var SalesShipmentHeader: Record "Sales Shipment Header") RecipientObj: JsonArray
    var
        RecipientDetailsAddressObj: JsonObject;
        RecipientAddressTokens: JsonObject;
        ContactObj: JsonObject;
        RecipientContactTokens: JsonObject;
        RecipientStreetLinesArray: JsonArray;
    begin
        RecipientStreetLinesArray.Add(SalesShipmentHeader."Ship-to Address");
        RecipientAddressTokens.Add('streetLines', RecipientStreetLinesArray);
        RecipientAddressTokens.Add('city', SalesShipmentHeader."Ship-to City");
        RecipientAddressTokens.Add('countryCode', 'GB');
        RecipientAddressTokens.Add('postalCode', SalesShipmentHeader."Ship-to Post Code");
        RecipientDetailsAddressObj.Add('address', RecipientAddressTokens);
        RecipientContactTokens.Add('companyName', SalesShipmentHeader."Ship-to Name");
        RecipientContactTokens.Add('emailAddress', SalesShipmentHeader."Sell-to E-Mail");
        RecipientContactTokens.Add('phoneNumber', SalesShipmentHeader."Sell-to Phone No.");
        RecipientContactTokens.Add('personName', SalesShipmentHeader."Ship-to Contact");
        RecipientDetailsAddressObj.Add('contact', RecipientContactTokens);
        RecipientObj.Add(RecipientDetailsAddressObj);
        exit(RecipientObj);
    end;

    local procedure GetShippingAgentServicesDescription(var SalesShipmentHeader: Record "Sales Shipment Header") ShippingAgentServDesc: Text
    var
        ShippingAgentServices: Record "Shipping Agent Services";
    begin
        ShippingAgentServices.Reset();
        if not ShippingAgentServices.Get(SalesShipmentHeader."Shipping Agent Code", SalesShipmentHeader."Shipping Agent Service Code") then
            Error('Please input a valid shipping agent service code and agent service.');
        ShippingAgentServices.FindSet();
        ShippingAgentServDesc := ShippingAgentServices.Description;
        exit(ShippingAgentServDesc);
    end;

    local procedure GetCustomerReferenceValues(var SalesShipmentHeader: Record "Sales Shipment Header") CustomerReferenceArray: JsonArray
    var
        CustomerReferenceTokens: JsonObject;
    begin
        CustomerReferenceTokens.Add('customerReferenceType', 'CUSTOMER_REFERENCE');
        CustomerReferenceTokens.Add('value', SalesShipmentHeader."Order No.");
        CustomerReferenceArray.Add(CustomerReferenceTokens);
        exit(CustomerReferenceArray);
    end;

    local procedure GetGroupPackageCount(var SalesShipmentLine: Record "Sales Shipment Line") GroupPackageCount: Integer
    begin
        Evaluate(GroupPackageCount, Format(Round(SalesShipmentLine.Quantity, 1, '=')));
        exit(GroupPackageCount);
    end;

    local procedure GetLabelSpecificationObject() LabelSpecificationObject: JsonObject
    begin
        LabelSpecificationObject.Add('labelFormatType', 'COMMON2D');
        LabelSpecificationObject.Add('labelStockType', Format(FedexSetup.LabelStockType));
        LabelSpecificationObject.Add('imageType', Format(FedexSetup.ImageType));
        exit(LabelSpecificationObject);
    end;

    local procedure GetPickUpType(var PickUpTypes: Enum "Fedex PickUp Types") Result: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPickUpType(PickUpTypes, IsHandled, Result);
        if IsHandled then
            exit(Result);

        case PickUpTypes of
            PickUpTypes::contact_fedex_to_schedule:
                begin
                    Result := 'CONTACT_FEDEX_TO_SCHEDULE';
                    exit(Result);
                end;
            PickUpTypes::droppoff_at_fedex_location:
                begin
                    Result := 'DROPOFF_AT_FEDEX_LOCATION';
                    exit(Result);
                end;
            PickUpTypes::use_scheduled_pickup:
                begin
                    Result := 'USE_SCHEDULED_PICKUP';
                    exit(Result);
                end;
        end;
    end;

    local procedure GetResponseText(Response: HttpResponseMessage): Text
    var
        ResponseInStream: InStream;
        ResponseText: Text;
    begin
        Response.Content().ReadAs(ResponseInStream);
        ResponseInStream.ReadText(ResponseText);
        exit(ResponseText);
    end;

    var
        Token: Text;
        HttpClient: HttpClient;
        RequestContent: HttpContent;
        Response: HttpResponseMessage;
        Body: JsonObject;
        Payload: Text;
        FedexSetup: Record "Fedex Setup";
        LabelCreationResponse: Codeunit "Label Creation Response";
        FedexHttpErrorHandler: Codeunit "Fedex Http Error Handler";
        TotalWeight: Decimal;
        SalesShipmentLine: Record "Sales Shipment Line";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetContentHeaders(var Content: HttpContent; var ContentHeaders: HttpHeaders; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPickUpType(var PickUpTypes: Enum "Fedex PickUp Types"; var IsHandled: Boolean; var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetContentHeaders(var Content: HttpContent; var ContentHeaders: HttpHeaders)
    begin
    end;
}