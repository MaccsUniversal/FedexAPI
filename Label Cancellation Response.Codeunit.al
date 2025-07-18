codeunit 50110 "Label Cancellation Response"
{
    Permissions = tabledata "Sales Shipment Header" = M;

    trigger OnRun()
    begin
        CancelResponseHandler();
    end;

    local procedure CancelResponseHandler()
    var
        ResponseAsText: Text;
        ResponseObj: JsonObject;
        OutputToken: JsonToken;
        OutputObj: JsonObject;
        CancelledShipmentToken: JsonToken;
        CancelledShipmentValue: JsonValue;
        CancelledShipmentAsText: Text;
        AlertsArray: JsonToken;
        Array: JsonArray;
        ArrayToken: JsonToken;
        ArrayObj: JsonObject;
        MessageToken: JsonToken;
        MessageValue: JsonValue;
        MessageAsText: Text;
    begin
        ResponseData.Content.ReadAs(ResponseAsText);
        ResponseObj.ReadFrom(ResponseAsText);
        ResponseObj.Get('output', OutputToken);
        OutputObj := OutputToken.AsObject();
        OutputObj.Get('alerts', AlertsArray);
        Array := AlertsArray.AsArray();
        Array.Get(0, ArrayToken);
        ArrayObj := ArrayToken.AsObject();
        ArrayObj.Get('message', MessageToken);
        MessageValue := MessageToken.AsValue();
        MessageValue.WriteTo(MessageAsText);
        MessageAsText := MessageAsText.Replace('"', '');
        OutputObj.Get('cancelledShipment', CancelledShipmentToken);
        CancelledShipmentValue := CancelledShipmentToken.AsValue();
        CancelledShipmentValue.WriteTo(CancelledShipmentAsText);
        CancelledShipmentAsText := CancelledShipmentAsText.Replace('"', '');

        ShowMessage(CancelledShipmentAsText, MessageAsText);
        RemoveTrackingNumber();
    end;

    local Procedure RemoveTrackingNumber()
    var
        SalesOrderHeader: Record "Sales Header";
        OrderNo: Code[20];
    begin
        OrderNo := SalesShipmentHeader."Order No.";

        SalesShipmentHeader."Fedex Tracking No." := '';
        SalesShipmentHeader."Label Status" := SalesShipmentHeader."Label Status"::Cancelled;
        SalesShipmentHeader.Modify();

        if SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, OrderNo) then begin
            SalesOrderHeader."Fedex Tracking No." := '';
            SalesOrderHeader."Label Status" := SalesOrderHeader."Label Status"::Cancelled;
            SalesOrderHeader.Modify();
        end;
    end;

    local procedure ShowMessage(CancelledText: Text; MessageText: Text)
    begin
        if HideDialog then
            exit;

        MessageToShow(CancelledText, MessageText);
    end;

    local procedure MessageToShow(Cancelled: Text; Msg: Text)
    begin
        case Cancelled of
            'true':
                begin
                    Message(Msg);
                end;
            'false':
                begin
                    Error(Msg);
                end;
        end;
    end;


    procedure SetResponseData(Response: HttpResponseMessage)
    begin
        ResponseData := Response;
    end;

    procedure SetShipmentHeader(ShipmentHeader: Record "Sales Shipment Header")
    begin
        SalesShipmentHeader := ShipmentHeader;
    end;

    procedure SetHideDialoge(Hide: Boolean)
    begin
        HideDialog := Hide;
    end;

    var
        ResponseData: HttpResponseMessage;
        SalesShipmentHeader: Record "Sales Shipment Header";
        HideDialog: Boolean;
}