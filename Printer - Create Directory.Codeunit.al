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
        OrderNumber := SalesShipmentHeader."Order No.";
        SalesOrderObj.Add('salesOrderNumber', OrderNumber);
        SalesOrderObj.WriteTo(Payload);
        RequestContent.WriteFrom(Payload);
        RequestContent.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');
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
}