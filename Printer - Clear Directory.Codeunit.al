codeunit 50108 "Printer - Clear Directory"
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
        Path := 'https://perch-moral-purely.ngrok-free.app/';
        Endpoint := 'clear_directory';
        IsSuccessful := Client.Put(Path + Endpoint, RequestContent, Response);

        if IsSuccessful then
            FedexErrorHandler.HandleHttpError(Response);

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
        SalesOrderObj.Add('salesOrderNumber', ShpmntHdr."Order No.");
        SalesOrderObj.WriteTo(Payload);
        Content.WriteFrom(Payload);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');
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
}