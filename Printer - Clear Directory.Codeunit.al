codeunit 99019 "Printer - Clear Directory"
{
    trigger OnRun()
    begin
        ReqContent := SetContent(Shipment);
        CallCheckDirectory(ReqContent);
    end;

    local procedure CallCheckDirectory(RequestContent: HttpContent)
    var
        Path: Text;
        Endpoint: Text;
        IsSuccessful: Boolean;
        Response: HttpResponseMessage;
    begin
        IsHandled := false;
        OnBeforeCallCheckDirectory(Client, IsHandled);
        if IsHandled then
            exit;
        Path := 'https://perch-moral-purely.ngrok-free.app/';
        Endpoint := 'clear_directory';
        IsSuccessful := Client.Put(Path + Endpoint, RequestContent, Response);

        if IsSuccessful then
            FedexErrorHandler.HandleHttpError(Response);

        OnAfterCallCheckDirectory(Response);
        SetRecordExists();
    end;

    local procedure SetRecordExists()
    begin
        RecordExists := true;
    end;

    procedure GetRecordExists(): Boolean;
    begin
        exit(RecordExists);
    end;

    local procedure SetContent(ShpmntHdr: Record "Sales Shipment Header") Content: HttpContent
    var
        ContentHeaders: HttpHeaders;
        SalesOrderObj: JsonObject;
        Payload: Text;
    begin
        IsHandled := false;
        OnBeforeSetContent(ShpmntHdr, Content, IsHandled);
        if IsHandled then
            exit(Content);

        SalesOrderObj.Add('salesOrderNumber', ShpmntHdr."Order No.");
        SalesOrderObj.WriteTo(Payload);
        Content.WriteFrom(Payload);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');
        OnAfterSetContent(Content);
        exit(Content);
    end;

    procedure SetSalesShipment(SalesShipment: Record "Sales Shipment Header")
    begin
        Shipment := SalesShipment;
    end;

    var
        Shipment: Record "Sales Shipment Header";
        ReqContent: HttpContent;
        Client: HttpClient;
        FedexErrorHandler: Codeunit "Fedex Http Error Handler";
        RecordExists: Boolean;
        IsHandled: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallCheckDirectory(var Client: HttpClient; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetContent(var ShpmntHdr: Record "Sales Shipment Header"; var Content: HttpContent; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetContent(var Content: HttpContent)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCallCheckDirectory(var Response: HttpResponseMessage)
    begin
    end;
}