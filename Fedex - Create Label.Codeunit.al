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

    procedure SetShipmentLines(var ShipmentHeaderLines: Record "Sales Shipment Line")
    begin
        SalesShipmentLine.copy(ShipmentHeaderLines);
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
        ReqObj: Text;
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
        RequestedShipmentObj.WriteTo(ReqObj);
        // Message(ReqObj);
        exit(RequestedShipmentObj);
    end;

    local procedure GetAccountNumber() AccountNumber: JsonObject
    begin
        AccountNumber.Add('value', FedexSetup.AccountNumber);
        exit(AccountNumber);
    end;

    local procedure GetDescription(var SalesShipmentLine: Record "Sales Shipment Line") Description: Text
    var
        DescEdited: Text;
    begin
        if StrLen(SalesShipmentLine.Description) > 50 then begin
            Description := Format(SalesShipmentLine.Description, 50);
        end else begin
            Description := Format(SalesShipmentLine.Description, StrLen(SalesShipmentLine.Description));
        end;
        Description := Description.Trim();
        exit(Description);
    end;

    local procedure GetShipperJsonObject() ShipperObj: JsonObject
    var
        ShipperAddObj: JsonObject;
        ShipperAddTokens: JsonObject;
        ShipperStreetLinesArray: JsonArray;
        ShipperContact: JsonObject;
        CompanyInfo: Record "Company Information";
        Address: Text;
        Address2: Text;
        PostCode: Text;
        CountryRegionCode: Text;
        Name: Text;
        PhoneNumber: Text;
        Contact: Text;
    begin
        if not CompanyInfo.Find('-') then
            Error('Company Information not found');

        if StrLen(CompanyInfo.Address) > 35 then begin
            Address := Format(CompanyInfo.Address, 35);
        end else begin
            Address := Format(CompanyInfo.Address);
        end;
        ShipperStreetLinesArray.Add(Address);

        if StrLen(CompanyInfo."Address 2") > 35 then begin
            Address2 := Format(CompanyInfo."Address 2", 35);
        end else begin
            Address2 := Format(CompanyInfo."Address 2");
        end;
        ShipperStreetLinesArray.Add(CompanyInfo."Address 2");
        ShipperAddTokens.Add('streetLines', ShipperStreetLinesArray);
        ShipperAddTokens.Add('city', 'Bedford');

        if StrLen(CompanyInfo."Post Code") > 10 then begin
            PostCode := Format(CompanyInfo."Post Code", 10);
        end else begin
            PostCode := Format(CompanyInfo."Post Code");
        end;
        ShipperAddTokens.Add('postalCode', CompanyInfo."Post Code");

        if StrLen(CompanyInfo."Country/Region Code") > 2 then begin
            CountryRegionCode := Format(CompanyInfo."Country/Region Code", 2);
        end else begin
            CountryRegionCode := Format(CompanyInfo."Country/Region Code");
        end;

        if CountryRegionCode <> 'GB' then
            Error('Company Information: Country/Region Code must =''GB''');
        ShipperAddTokens.Add('countryCode', CompanyInfo."Country/Region Code");
        ShipperAddTokens.Add('residential', false);
        if StrLen(CompanyInfo.Name) > 35 then begin
            Name := Format(CompanyInfo.Name, 35);
        end else begin
            Name := Format(CompanyInfo.Name);
        end;
        ShipperContact.Add('personName', CompanyInfo.Name);
        PhoneNumber := CompanyInfo."Phone No.".Replace(' ', '');
        if StrLen(PhoneNumber) > 15 then begin
            PhoneNumber := Format(PhoneNumber, 15);
        end else begin
            PhoneNumber := Format(PhoneNumber);
        end;
        ShipperContact.Add('phoneNumber', PhoneNumber.Trim());
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
        Address: Text;
        City: Text;
        PhoneNumber: Text;
        EmailAddress: Text;
        CompanyName: Text;
        PostCode: Text;
        Contact: Text;
    begin
        if StrLen(SalesShipmentHeader."Ship-to Address") > 35 then begin
            Address := Format(SalesShipmentHeader."Ship-to Address", 35);
        end else begin
            Address := Format(SalesShipmentHeader."Ship-to Address");
        end;
        RecipientStreetLinesArray.Add(Address);
        RecipientAddressTokens.Add('streetLines', RecipientStreetLinesArray);

        if StrLen(SalesShipmentHeader."Ship-to City") > 35 then begin
            City := Format(SalesShipmentHeader."Ship-to City", 35);
        end else begin
            City := Format(SalesShipmentHeader."Ship-to City");
        end;
        RecipientAddressTokens.Add('city', City);
        RecipientAddressTokens.Add('countryCode', 'GB');

        if StrLen(SalesShipmentHeader."Ship-to Post Code") > 35 then begin
            PostCode := Format(SalesShipmentHeader."Ship-to Post Code", 35);
        end else begin
            PostCode := Format(SalesShipmentHeader."Ship-to Post Code");
        end;
        RecipientAddressTokens.Add('postalCode', Postcode);
        RecipientDetailsAddressObj.Add('address', RecipientAddressTokens);

        if StrLen(SalesShipmentHeader."Ship-to Name") > 35 then begin
            CompanyName := Format(SalesShipmentHeader."Ship-to Name", 35);
        end else begin
            CompanyName := Format(SalesShipmentHeader."Ship-to Name", StrLen(SalesShipmentHeader."Ship-to Name"));
        end;
        RecipientContactTokens.Add('companyName', CompanyName);

        EmailAddress := SplitEmailAddress(SalesShipmentHeader."Sell-to E-Mail");
        if StrLen(EmailAddress) > 80 then begin
            EmailAddress := Format(EmailAddress, 80);
        end else begin
            EmailAddress := Format(EmailAddress);
        end;
        RecipientContactTokens.Add('emailAddress', EmailAddress);

        If SalesShipmentHeader."Sell-to Phone No." = '' then
            Error('Please enter a valid phone number on the customer card.');
        PhoneNumber := SalesShipmentHeader."Sell-to Phone No.".Replace(' ', '');
        if StrLen(PhoneNumber) > 15 then begin
            PhoneNumber := Format(PhoneNumber, 15);
        end else begin
            PhoneNumber := Format(PhoneNumber);
        end;
        RecipientContactTokens.Add('phoneNumber', PhoneNumber.Trim());

        if StrLen(SalesShipmentHeader."Ship-to Contact") > 35 then begin
            Contact := Format(SalesShipmentHeader."Ship-to Contact", 35);
        end else begin
            Contact := Format(SalesShipmentHeader."Ship-to Contact");
        end;
        RecipientContactTokens.Add('personName', SalesShipmentHeader."Ship-to Contact");
        RecipientDetailsAddressObj.Add('contact', RecipientContactTokens);
        RecipientObj.Add(RecipientDetailsAddressObj);
        exit(RecipientObj);
    end;

    local Procedure SplitEmailAddress(var Input: Text) UsableEmailAddress: Text
    var
        Selected: Integer;
        SplitList: List of [Text];
        EmailOptions: Text;
        Text000: Label 'Customer email for label';
    begin
        if not Input.Contains(';') then
            exit(Input);

        EmailOptions := Input.Replace(';', ',');
        Selected := StrMenu(EmailOptions, 1, Text000);
        SplitList := Input.Split(';');
        exit(SplitList.Get(Selected));
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