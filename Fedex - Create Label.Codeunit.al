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
        Result: HttpResponseMessage;
    begin
        IsHandled := false;
        BeforeCallShipAPI(HttpClient, IsHandled, Result);
        if IsHandled then
            exit(Result);

        Path := GetURLPath();
        Endpoint := '/ship/v1/shipments';
        IsSuccessful := HttpClient.Post(Path + Endpoint, RequestContent, Response);
        if IsSuccessful then
            FedexHttpErrorHandler.HandleHttpError(Response);

        AfterCallShipAPI(Response);
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

    local procedure GetAccessToken() Token: Text
    begin
        IsHandled := false;
        OnBeforeGetAccessToken(IsHandled, Token);
        if IsHandled then
            exit(Token);
        IsolatedStorage.Get('AccessToken', DataScope::Module, Token);
        exit(Token);
    end;

    local procedure SetAuthorizationHeader(Token: Text)
    begin
        IsHandled := false;
        OnBeforeSetAuthorizationHeader(HttpClient);
        if IsHandled then
            exit;
        HttpClient.DefaultRequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', Token));
        OnAfterSetAuthorizationHeader(HttpClient);
    end;

    local procedure SetContentHeaders(var SalesShipmentHeader: Record "Sales Shipment Header"): HttpContent
    var
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
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
        WeightObj: JsonObject;
        WeightValue: Decimal;
        AccountNumber: JsonObject;
        ReqObj: Text;
        Result: JsonObject;
    begin
        IsHandled := false;
        OnBeforeSetRequestBody(SalesShipmentHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        TotalPackageCount := 0;
        TotalWeight := 0;
        SequenceNumber := 1;
        if not FedexSetup.Find('-') then
            Error('Please complete Fedex Setup Page to continue.');
        ShipperObj := GetShipperJsonObject();
        OnAfterGetShipperJsonObject(ShipperObj);
        RequestedShipmentTokens.Add('shipper', ShipperObj);
        RecipientObj := GetRecipientJsonArray(SalesShipmentHeader);
        OnAfterGetRecipientJsonArray(SalesShipmentHeader, RecipientObj);
        RequestedShipmentTokens.Add('recipients', RecipientObj);
        PickUpTypEnum := GetPickUpType(FedexSetup.PickUpType);
        OnAfterGetPickUpType(PickUpTypEnum);
        RequestedShipmentTokens.Add('pickupType', PickUpTypEnum);// Should this field appear on the Posted Sales Shipment?
        ShippingAgentServicesDescription := GetShippingAgentServicesDescription(SalesShipmentHeader);
        OnAfterShippingAgentServicesDescription(SalesShipmentHeader, ShippingAgentServicesDescription);
        RequestedShipmentTokens.Add('serviceType', ShippingAgentServicesDescription);
        RequestedShipmentTokens.Add('packagingType', 'YOUR_PACKAGING');

        SalesShipmentLine.FindSet();
        repeat
            TotalWeight += (SalesShipmentLine."Gross Weight" * SalesShipmentLine."Qty. Shipped Not Invoiced");
            TotalPackageCount += SalesShipmentLine."Qty. Shipped Not Invoiced";
            RequestedPackageLineItemsTokens.Add('sequenceNumber', Format(SequenceNumber));
            RequestedPackageLineItemsTokens.Add('subPackagingType', SalesShipmentLine."Unit of Measure Code");
            CustomerReferenceArray := GetCustomerReferenceValues(SalesShipmentHeader);
            OnAfterGetCustomerReferenceValues(SalesShipmentHeader, CustomerReferenceArray);
            RequestedPackageLineItemsTokens.Add('customerReferences', CustomerReferenceArray.AsToken());
            RequestedPackageLineItemsTokens.Add('groupPackageCount', GetGroupPackageCount(SalesShipmentLine));
            WeightObj.Add('units', 'KG');
            WeightValue := GetWeightValue(SalesShipmentLine);
            OnAfterGetWeightValue(SalesShipmentLine, WeightValue);
            WeightObj.Add('value', WeightValue);
            RequestedPackageLineItemsTokens.Add('weight', WeightObj.AsToken());
            RequestedPackageLineItemsTokens.Add('itemDescription', GetDescription(SalesShipmentLine));
            RequestedPackageLineItemsArray.Add(RequestedPackageLineItemsTokens);
            Clear(RequestedPackageLineItemsTokens);
            Clear(WeightObj);
            Clear(CustomerReferenceArray);
            SequenceNumber += 1;
        until SalesShipmentLine.Next <= 0;
        RequestedShipmentTokens.Add('totalWeight', TotalWeight);
        ShippingChargesPaymentsTokens.Add('paymentType', 'SENDER');
        RequestedShipmentTokens.Add('shippingChargesPayment', ShippingChargesPaymentsTokens.AsToken());
        LabelSpecificationObj := GetLabelSpecificationObject();
        OnAfterGetLabelSpecificationObject(LabelSpecificationObj);
        RequestedShipmentTokens.Add('labelSpecification', LabelSpecificationObj);
        RateRequestType.Add('NONE');
        RequestedShipmentTokens.Add('rateRequestType', RateRequestType);
        RequestedShipmentTokens.Add('totalPackageCount', TotalPackageCount);
        RequestedShipmentTokens.Add('requestedPackageLineItems', RequestedPackageLineItemsArray);
        RequestedShipmentObj.Add('requestedShipment', RequestedShipmentTokens);
        RequestedShipmentObj.Add('labelResponseOptions', 'LABEL');
        AccountNumber := GetAccountNumber();
        OnAfterGetAccountNumber(AccountNumber);
        RequestedShipmentObj.Add('accountNumber', AccountNumber);
        RequestedShipmentObj.Add('oneLabelAtATime', false);
        RequestedShipmentObj.WriteTo(ReqObj);
        // Message(ReqObj);
        OnAfterSetRequestBody(SalesShipmentHeader, RequestedShipmentObj);
        exit(RequestedShipmentObj);
    end;

    local procedure GetWeightValue(var SalesShipmentLine: Record "Sales Shipment Line") CalcWeight: Decimal
    var
        BundleItem: Record "Fedex Bundle Items";
        CalcGroupPackageCount2: Decimal;
        GroupPackageCount2: Integer;
        Result: Decimal;
    begin
        if SalesShipmentLine."Gross Weight" = 0.0 then
            Error('Item No must have a Gross Weight. Shipment=%1. Line=%2. Item=%3. ', SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");
        BundleItem.Reset();
        if BundleItem.Get(SalesShipmentLine."No.") then begin
            BundleItem.FindSet();
            CalcGroupPackageCount2 := SalesShipmentLine.Quantity / BundleItem."Pcs. Per Parcel";
            Evaluate(GroupPackageCount2, Format(Round(CalcGroupPackageCount2, 1, '>')));
            CalcWeight := (SalesShipmentLine."Gross Weight" * SalesShipmentLine.Quantity) / GroupPackageCount2;
            exit(CalcWeight);
        end;
        CalcWeight := SalesShipmentLine."Gross Weight";
        exit(CalcWeight);
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
        ShipToContact: Text;
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

        If SalesShipmentHeader."Ship-to Phone No." = '' then begin
            PhoneNumber := GetPhoneNumber();
        end else begin
            PhoneNumber := Format(SalesShipmentHeader."Ship-to Phone No.");
        end;
        if StrLen(PhoneNumber) > 15 then begin
            PhoneNumber := Format(PhoneNumber, 15);
        end else begin
            PhoneNumber := Format(PhoneNumber);
        end;
        RecipientContactTokens.Add('phoneNumber', PhoneNumber.Trim());

        if StrLen(SalesShipmentHeader."Ship-to Contact") > 35 then begin
            ShipToContact := Format(SalesShipmentHeader."Ship-to Contact", 35);
        end else begin
            ShipToContact := Format(SalesShipmentHeader."Ship-to Contact");
        end;
        RecipientContactTokens.Add('personName', ShipToContact);
        RecipientDetailsAddressObj.Add('contact', RecipientContactTokens);
        RecipientObj.Add(RecipientDetailsAddressObj);
        exit(RecipientObj);
    end;

    local procedure GetPhoneNumber(): Text
    var
        Customer: Record Customer;
        Selected: Integer;
        PhoneOptions: Text;
        Text000: Label 'Customer phone number';
        SplitList: List of [Text];
        SelectedNumber: Text;
        Result: Text;
    begin
        IsHandled := false;
        OnBeforeGetPhoneNumber(SalesShipmentLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if not Customer.Get(SalesShipmentLine."Sell-to Customer No.") then
            exit;
        if (Customer."Phone No." = '') and (Customer."Mobile Phone No." = '') then
            Error('Please enter a Phone No. or Mobile No. on customer card for customer %1 ', Customer."No.");
        PhoneOptions := Customer."Phone No." + ',' + Customer."Mobile Phone No.";
        Selected := StrMenu(PhoneOptions, 1, Text000);
        if Selected = 0 then begin
            if Customer."Mobile Phone No." <> '' then begin
                exit(Customer."Mobile Phone No.");
            end else begin
                Error('Please select a phone number from customer card for customer %1 ', Customer."No.");
            end
        end;
        SplitList := PhoneOptions.Split(',');
        OnAfterGetPhoneNumber(SalesShipmentLine);
        exit(SplitList.Get(Selected));
    end;

    local Procedure SplitEmailAddress(var Input: Text) UsableEmailAddress: Text
    var
        Selected: Integer;
        SplitList: List of [Text];
        EmailOptions: Text;
        Text000: Label 'Customer email for label';
    begin
        IsHandled := false;
        OnBeforeSplitEmailAddress(SalesShipmentLine, UsableEmailAddress);
        if IsHandled then
            exit(UsableEmailAddress);
        if not Input.Contains(';') then
            exit(Input);

        EmailOptions := Input.Replace(';', ',');
        Selected := StrMenu(EmailOptions, 1, Text000);
        SplitList := Input.Split(';');
        OnAfterSplitEmailAddress(Input, EmailOptions, SplitList, Selected);
        exit(SplitList.Get(Selected));
    end;

    local procedure GetShippingAgentServicesDescription(var SalesShipmentHeader: Record "Sales Shipment Header") ShippingAgentServDesc: Text
    var
        ShippingAgentServices: Record "Shipping Agent Services";
    begin
        ShippingAgentServices.Reset();
        if not ShippingAgentServices.Get(SalesShipmentHeader."Shipping Agent Code", SalesShipmentHeader."Shipping Agent Service Code") then
            Error('Please input a valid shipping agent service code and agent service.');
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
    var
        BundleItem: Record "Fedex Bundle Items";
        CalcGroupPackageCount: Decimal;
    begin
        BundleItem.Reset();
        if BundleItem.Get(SalesShipmentLine."No.") then begin
            BundleItem.FindSet();
            CalcGroupPackageCount := SalesShipmentLine.Quantity / BundleItem."Pcs. Per Parcel";
            Evaluate(GroupPackageCount, Format(Round(CalcGroupPackageCount, 1, '>')));
            exit(GroupPackageCount);
        end;
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
        IsHandled: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetContentHeaders(var Content: HttpContent; var ContentHeaders: HttpHeaders; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPickUpType(var PickUpTypes: Enum "Fedex PickUp Types"; var IsHandled: Boolean; var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPhoneNumber(var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean; var Result: Text)
    begin
    end;

    local procedure OnBeforeSetRequestBody(var SalesShipmentHeader: Record "Sales Shipment Header"; var IsHandled: Boolean; var Result: JsonObject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure BeforeCallShipAPI(var HttpClient: HttpClient; var IsHandled: Boolean; var Result: HttpResponseMessage)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAuthorizationHeader(var HttpClient: HttpClient)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitEmailAddress(var SalesShipmentLine: Record "Sales Shipment Line"; var UsableEmailAddress: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitEmailAddress(var Input: Text; var EmailOptions: Text; var SpiltList: List of [Text]; var Selected: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountNumber(var AccountNumber: JsonObject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLabelSpecificationObject(var LabelSpecificationObj: JsonObject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetShipperJsonObject(var ShipperObj: JsonObject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecipientJsonArray(var SalesShipmentHeader: Record "Sales Shipment Header"; var RecipientObj: JsonArray)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPickUpType(var PickUpTypEnum: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShippingAgentServicesDescription(var SalesShipmentHeader: Record "Sales Shipment Header"; var ShippingAgentServicesDescription: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustomerReferenceValues(var SalesShipmentHeader: Record "Sales Shipment Header"; var CustomerReferenceArray: JsonArray)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWeightValue(var SalesShipmentLine: Record "Sales Shipment Line"; var CalcWeight: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAuthorizationHeader(var HttpClient: HttpClient)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAccessToken(var IsHandled: Boolean; var Token: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure AfterCallShipAPI(var Response: HttpResponseMessage)
    begin
    end;


    local procedure OnAfterSetRequestBody(var SalesShipmentHeader: Record "Sales Shipment Header"; var RequestedShipmentObj: JsonObject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPhoneNumber(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetContentHeaders(var Content: HttpContent; var ContentHeaders: HttpHeaders)
    begin
    end;
}