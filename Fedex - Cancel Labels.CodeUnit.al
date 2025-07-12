codeunit 50107 "Fedex - Cancel Labels"
{
    TableNo = "Sales Shipment Header";
    Permissions = tabledata "Sales Shipment Header" = M;

    trigger OnRun()
    begin
        RefreshToken();
        Token := GetAccessToken();
        SetAuthorizationHeader(Token);
        RequestContent := SetContentHeaders(Rec);
        CheckDirectoryExists(Rec);
        CallCancelAPI();
    end;

    local procedure CallCancelAPI()
    var
        Path: Text;
        Endpoint: Text;
        IsSuccessful: Boolean;
        Response: HttpResponseMessage;
        Rtext: Text;
    begin
        Path := GetURLPath();
        Endpoint := '/ship/v1/shipments/cancel';
        IsSuccessful := HttpClient.Put(Path + Endpoint, RequestContent, Response);
        if IsSuccessful then
            FedexHttpErrorHandler.HandleHttpError(Response);

        Response.Content.ReadAs(Rtext);
        Message(Rtext);
    end;

    local procedure GetURLPath() Path: Text
    begin
        if not FedexSetup.Find('-') then
            exit;

        Path := FedexSetup.URI;
        exit(Path);
    end;

    local procedure CheckDirectoryExists(SalesShipment: Record "Sales Shipment Header")
    var
        PrinterClearDirectory: Codeunit "Printer - Clear Directory";
    begin
        PrinterClearDirectory.SetSalesShipment(SalesShipment);
        PrinterClearDirectory.Run();
    end;

    local procedure SetRequestBody(var SalesShipmentHeader: Record "Sales Shipment Header") CancelShipmentObject: JsonObject
    var
        AccountNumberObj: JsonObject;
        ValueObject: JsonObject;
    begin
        if FedexSetup.Find('-') then begin
            ValueObject.Add('value', FedexSetup.AccountNumber);
            CancelShipmentObject.Add('accountNumber', ValueObject);
            CancelShipmentObject.Add('emailShipment', false);
            CancelShipmentObject.Add('senderCountryCode', 'GB');
            CancelShipmentObject.Add('trackingNumber', SalesShipmentHeader."Package Tracking No.");
        end;
        exit(CancelShipmentObject)
    end;

    local procedure SetContentHeaders(var SalesShipmentHeader: Record "Sales Shipment Header"): HttpContent
    var
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        IsHandled: Boolean;
    begin
        if SalesShipmentHeader."Package Tracking No." = '' then
            Error('Package Tracking Number cannot be blank. Shipment No.= %1', SalesShipmentHeader."No.");

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

    var
        Token: Text;
        FedexSetup: Record "Fedex Setup";
        FedexHttpErrorHandler: Codeunit "Fedex Http Error Handler";
        HttpClient: HttpClient;
        Body: JsonObject;
        RequestContent: HttpContent;
        Payload: Text;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetContentHeaders(var Content: HttpContent; var ContentHeaders: HttpHeaders; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterSetContentHeaders(var Content: HttpContent; var ContentHeaders: HttpHeaders)
    begin
    end;
}

