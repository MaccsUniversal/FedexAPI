codeunit 50106 "Printer - Create Directory"
{
    trigger OnRun()
    begin
        Content := SetContent();
        CheckDirectoryAPI(Content);
    end;

    procedure GetIsOk(): Boolean
    begin
        exit(IsOk);
    end;

    local procedure CheckDirectoryAPI(Content: HttpContent) Ok: Boolean
    var
        ResponseMessage: HttpResponseMessage;
        IsSuccessful: Boolean;
        Path: Text;
        Endpoint: Text;
    begin
        IsHandled := false;
        OnBeforeCheckDirectoryAPI(Content, OK, IsHandled);
        if IsHandled then
            exit;
        Path := 'https://perch-moral-purely.ngrok-free.app/';
        Endpoint := 'create_directory';
        IsSuccessful := Client.Post(Path + Endpoint, Content, ResponseMessage);
        if IsSuccessful then
            FedexHttpErrorHandler.HandleHttpError(ResponseMessage);
    end;

    local procedure SetContent() RequestContent: HttpContent
    var
        ContentHeaders: HttpHeaders;
        OrderNumber: Text;
        Payload: Text;
        SalesOrderObj: JsonObject;
    begin
        IsHandled := false;
        OnBeforeSetContent(SalesShipmentHeader, IsHandled, RequestContent);
        if IsHandled then
            exit(RequestContent);
        OrderNumber := SalesShipmentHeader."Order No.";
        SalesOrderObj.Add('salesOrderNumber', OrderNumber);
        SalesOrderObj.WriteTo(Payload);
        RequestContent.WriteFrom(Payload);
        RequestContent.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');
        OnAfterSetContent(RequestContent);
        exit(RequestContent);
    end;

    procedure SetSalesShipmentHeader(ShipmentHeader: Record "Sales Shipment Header")
    begin
        SalesShipmentHeader := ShipmentHeader;
    end;

    var
        Client: HttpClient;
        Content: HttpContent;
        SalesShipmentHeader: Record "Sales Shipment Header";
        FedexSetup: Record "Fedex Setup";
        IsOk: Boolean;
        FedexHttpErrorHandler: Codeunit "Fedex Http Error Handler";
        IsHandled: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDirectoryAPI(var Content: HttpContent; var OK: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetContent(var SalesShipmentHeader: Record "Sales Shipment Header"; var IsHandled: Boolean; var RequestContent: HttpContent)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetContent(var RequestContent: HttpContent)
    begin
    end;
}