codeunit 50102 "Fedex - Create Shipment"
{
    TableNo = "Sales Shipment Header";
    trigger OnRun()
    var
        ResponseText: Text;
        ResponseJSON: JsonObject;
        ResponseJSONAsText: Text;
    begin
        IsolatedStorage.Get('AccessToken', DataScope::Module, AccessTkn);
        HttpClient.DefaultRequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', AccessTkn));
        RequestContent := SetContentHeaders(Rec);
        HttpClient.Post('https://apis-sandbox.fedex.com/ship/v1/shipments', RequestContent, Response);
        Response.Content.ReadAs(ResponseText);
        if response.HttpStatusCode <> 200 then begin
            ResponseJSON.ReadFrom(ResponseText);
            ResponseJSON.WriteTo(ResponseJSONAsText);
            Message(ResponseJSONAsText);
        end
        else
            Message(ResponseText);
    end;

    local procedure BuildRequestBody(var SalesShipmentHeader: Record "Sales Shipment Header"): JsonObject
    var
        SalesShipmenLine: Record "Sales Shipment Line";
        CompanyInfo: Record "Company Information";
        PickUpTypEnum: Enum "Fedex PickUp Types";
        ShippingAgentServices: Record "Shipping Agent Services";

        RequestedShipmentObj: JsonObject;
        RequestedShipmentTokens: JsonObject;

        ShipperAddObj: JsonObject;
        ShipperAddTokens: JsonObject;
        ShipperStreetLinesArray: JsonArray;
        ShipperContact: JsonObject;

        AddressObj: JsonObject;
        AddressTokens: JsonObject;

        ContactObj: JsonObject;
        ContactTokens: JsonObject;
        RecipientStreetLinesArray: JsonArray;

        RecipientObj: JsonArray;

        ShippingChargesPaymentsObj: JsonObject;
        ShippingChargesPaymentsTokens: JsonObject;

        LabelSpecificationObj: JsonObject;
        LabelSpecificationTokens: JsonObject;

        RequestedPackageLineItemsArray: JsonArray;
        RequestedPackageLineItemsObj: JsonObject;
        RequestedPackageLineItemsTokens: JsonObject;
        RequestedPackageLineItemsAsText: Text;

        CustomerReferenceTokens: JsonObject;
        CustomerReferenceArray: JsonArray;

        RateRequestType: JsonArray;

        DeclaredValue: JsonObject;
        Weight: JsonObject;

        AccountNumber: JsonObject;

        SequenceNumber: Integer;
        GroupPackageCount: Integer;
        TotalPackageCount: Integer;
        Description: Text;
    begin
        TotalPackageCount := 0;
        TotalWeight := 0;
        SequenceNumber := 1;
        if not FedexSetup.Get('FEDEXAPI') then
            Error('Please complete Fedex Setup to continue.');
        if not CompanyInfo.Get('') then
            Error('Unable to access Compnay Information because this is a value entered for the Primary Key field.');
        ShipperStreetLinesArray.Add(CompanyInfo."Ship-to Address");
        ShipperAddTokens.Add('streetLines', ShipperStreetLinesArray);
        ShipperAddTokens.Add('city', 'Luton');
        ShipperAddTokens.Add('postalCode', CompanyInfo."Ship-to Post Code");
        ShipperAddTokens.Add('countryCode', CompanyInfo."Ship-to Country/Region Code");
        ShipperAddTokens.Add('residential', false);
        ShipperContact.Add('personName', CompanyInfo."Ship-to Contact");
        ShipperContact.Add('phoneNumber', CompanyInfo."Ship-to Phone No.");
        ShipperAddObj.Add('address', ShipperAddTokens);
        ShipperAddObj.Add('contact', ShipperContact);
        RequestedShipmentTokens.Add('shipper', ShipperAddObj);
        RecipientStreetLinesArray.Add(SalesShipmentHeader."Ship-to Address");
        AddressTokens.Add('streetLines', RecipientStreetLinesArray);
        AddressTokens.Add('city', SalesShipmentHeader."Ship-to City");
        AddressTokens.Add('countryCode', 'GB');
        AddressTokens.Add('postalCode', SalesShipmentHeader."Ship-to Post Code");
        AddressObj.Add('address', AddressTokens);
        ContactTokens.Add('companyName', SalesShipmentHeader."Ship-to Name");
        ContactTokens.Add('emailAddress', SalesShipmentHeader."Sell-to E-Mail");
        ContactTokens.Add('phoneNumber', SalesShipmentHeader."Sell-to Phone No.");
        ContactTokens.Add('personName', SalesShipmentHeader."Ship-to Contact");
        AddressObj.Add('contact', ContactTokens);
        RecipientObj.Add(AddressObj);
        RequestedShipmentTokens.Add('recipients', RecipientObj);
        RequestedShipmentTokens.Add('pickupType', GetPickUpType(FedexSetup.PickUpType));// SHould this field appear on the Posted Sales Shipment?
        ShippingAgentServices.Reset();
        if not ShippingAgentServices.Get(SalesShipmentHeader."Shipping Agent Code", SalesShipmentHeader."Shipping Agent Service Code") then
            Error('Please input a valid shipping agent service code and agent service.');
        ShippingAgentServices.FindSet();
        RequestedShipmentTokens.Add('serviceType', ShippingAgentServices.Description);
        RequestedShipmentTokens.Add('packagingType', 'YOUR_PACKAGING');
        SalesShipmenLine.Reset();
        SalesShipmenLine.SetFilter("Document No.", SalesShipmentHeader."No.");
        SalesShipmenLine.FindSet();
        //check that line is an item before doing repeat until.
        repeat
            TotalWeight += (SalesShipmenLine."Gross Weight" * SalesShipmenLine."Qty. Shipped Not Invoiced");
            TotalPackageCount += SalesShipmenLine."Qty. Shipped Not Invoiced";
            // RequestedPackageLineItemsTokens.Add('sequenceNumber', Format(SequenceNumber));
            // RequestedPackageLineItemsTokens.Add('subPackagingType', SalesShipmenLine."Unit of Measure Code");
            // CustomerReferenceTokens.Add('customerReferenceType', 'Sales Order No.');
            // CustomerReferenceTokens.Add('value', SalesShipmentHeader."Order No.");
            // CustomerReferenceArray.Add(CustomerReferenceTokens);
            // RequestedPackageLineItemsTokens.Add('customerReferences', CustomerReferenceArray.AsToken());
            // DeclaredValue.Add('amount', SalesShipmenLine."Unit Price");
            // DeclaredValue.Add('currency', 'GBP');
            // RequestedPackageLineItemsTokens.Add('declaredValue', DeclaredValue.AsToken());
            Weight.Add('units', 'KG');
            Weight.Add('value', SalesShipmenLine."Gross Weight");
            RequestedPackageLineItemsTokens.Add('weight', Weight.AsToken());
            // Evaluate(GroupPackageCount, Format(Round(SalesShipmenLine.Quantity, 1, '=')));
            // RequestedPackageLineItemsTokens.Add('groupPackageCount', GroupPackageCount);
            // Description := Format(SalesShipmenLine.Description, 50);
            // Description := Description.Replace(' ', '');
            // RequestedPackageLineItemsTokens.Add('itemDescription', Description);
            RequestedPackageLineItemsArray.Add(RequestedPackageLineItemsTokens);
            Clear(RequestedPackageLineItemsTokens);
            Clear(CustomerReferenceTokens);
            Clear(DeclaredValue);
            Clear(Weight);
            Clear(CustomerReferenceArray);
            SequenceNumber += 1;
        until SalesShipmenLine.Next <= 0;
        RequestedShipmentTokens.Add('totalWeight', TotalWeight);
        ShippingChargesPaymentsTokens.Add('PaymentType', 'SENDER');
        RequestedShipmentTokens.Add('shippingChargesPayment', ShippingChargesPaymentsTokens.AsToken());
        LabelSpecificationTokens.Add('labelStockType', Format(FedexSetup.LabelStockType));
        LabelSpecificationTokens.Add('imageType', Format(FedexSetup.ImageType));
        RequestedShipmentTokens.Add('labelSpecification', LabelSpecificationTokens);
        RateRequestType.Add('ACCOUNT');
        RequestedShipmentTokens.Add('rateRequestType', RateRequestType);
        RequestedShipmentTokens.Add('totalPackageCount', TotalPackageCount);
        RequestedShipmentTokens.Add('requestedPackageLineItems', RequestedPackageLineItemsArray);
        AccountNumber.Add('value', FedexSetup.AccountNumber);
        RequestedShipmentObj.Add('requestedShipment', RequestedShipmentTokens);
        RequestedShipmentObj.Add('labelResponseOptions', 'LABEL');
        RequestedShipmentObj.Add('accountNumber', AccountNumber);
        RequestedShipmentObj.Add('oneLabelAtATime', false);
        Message(Format(RequestedShipmentObj));
        exit(RequestedShipmentObj);
    end;

    local procedure GetPickUpType(var PickUpTypes: Enum "Fedex PickUp Types"): Text
    begin
        case PickUpTypes of
            PickUpTypes::contact_fedex_to_schedule:
                begin
                    exit('CONTACT_FEDEX_tO_SCHEDULE');
                end;
            PickUpTypes::droppoff_at_fedex_location:
                begin
                    exit('DROPOFF_AT_FEDEX_LOCATION');
                end;
            PickUpTypes::use_scheduled_pickup:
                begin
                    exit('USE_SCHEDULED_PICKUP');
                end;
        end;
    end;

    local procedure SetContentHeaders(var SalesShipmentHeader: Record "Sales Shipment Header"): HttpContent
    var
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        IsHandled: Boolean;
    begin
        // IsolatedStorage.Get('AccessToken', DataScope::Module, AccessTkn);// error check if access token exists and is not expired. write separate procedure for this.
        IsHandled := false;
        OnBeforeSetContentHeaders(Content, ContentHeaders, IsHandled);
        if IsHandled then
            exit(Content);

        ContentObj := BuildRequestBody(SalesShipmentHeader);
        ContentObj.WriteTo(Payload);
        Content.WriteFrom(Payload);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        // ContentHeaders.Add('Authorization', StrSubstNo('Bearer %1', AccessTkn)); //fix this line too. HttpClient.DefaultRequestHeaders().Add('Authorization', AuthString);,Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', AuthToken))
        ContentHeaders.Add('x-customer-transaction-id', '624deea6-b709-470c-8c39-4b5511281492');
        ContentHeaders.Add('Content-Type', 'application/json');
        ContentHeaders.Add('X-locale', 'en_GB');
        OnAfterSetContentHeaders(Content, ContentHeaders);
        exit(Content);
    end;

    var
        AccessTkn: Text;
        HttpClient: HttpClient;
        RequestContent: HttpContent;
        Response: HttpResponseMessage;
        ContentObj: JsonObject;
        Payload: Text;
        FedexSetup: Record "Fedex Setup";
        TotalWeight: Decimal;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetContentHeaders(var Content: HttpContent; var ContentHeaders: HttpHeaders; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetContentHeaders(var Content: HttpContent; var ContentHeaders: HttpHeaders)
    begin
    end;
}