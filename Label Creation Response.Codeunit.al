codeunit 50103 "Label Creation Response"
{
    Permissions = tabledata "Sales Shipment Header" = M;
    trigger OnRun()
    begin
        PieceArrayToken := CreationResponseHandler();
        PrintLabelArray := SetPrintLabelArray(PieceArrayToken);
        PrintLabels.SetReqBody(PrintLabelArray);
        PrintLabels.Run();
        SetTrackingNumberFromResponse(ResponseData, SalesShipmentHeader);
        OnAfterSetTrackingNumberFromResponse(ResponseData, SalesShipmentHeader);
    end;

    procedure SetResponseData(Response: HttpResponseMessage)
    begin
        ResponseData := Response;
    end;

    procedure SetShipmentHeader(ShipmentHeader: Record "Sales Shipment Header")
    begin
        SalesShipmentHeader := ShipmentHeader;
    end;

    local procedure CreationResponseHandler() ArrayToken: JsonToken
    var
        ResponseObjectAsText: Text;
        ResponseObj: JsonObject;
        OutputToken: JsonToken;
        transactionShipmentsToken: JsonToken;
        transactionShipments0: JsonToken;
        PackageDocuments: JsonToken;
        PackageDocumentsToken: JsonToken;
        AlertsArray: JsonToken;
        AlertsText: Text;
    begin
        OnBeforeCreationResponseHandler(ResponseData, IsHandled, ArrayToken);
        if IsHandled then
            exit(ArrayToken);
        ResponseData.Content.ReadAs(ResponseObjectAsText);
        ResponseObj.ReadFrom(ResponseObjectAsText);
        ResponseObj.Get('output', OutputToken);
        if OutputToken.AsObject().Get('alerts', AlertsArray) then
            AlertsText := AlertsArray.AsArray().GetText(1);
        if AlertsText = 'WARNING' then
            Error(AlertsArray.AsArray.GetText(2));
        OutputToken.AsObject().Get('transactionShipments', transactionShipmentsToken);
        transactionShipmentsToken.AsArray().Get(0, transactionShipments0);
        transactionShipments0.AsObject().Get('pieceResponses', ArrayToken);
        OnAfterCreationResponseHandler(ArrayToken);
        exit(ArrayToken);
    end;

    local procedure SetPrintLabelArray(ResponseToken: JsonToken) LabelsToPrintObject: JsonObject
    var
        ArrayCount: Integer;
        EncodedLabelToken: JsonToken;
        LabelsToPrint: JsonArray;
        LabelToken: JsonObject;
        pieceResponsesToken: JsonToken;
        PackageDocuments: JsonToken;
        PackageDocumentsToken: JsonToken;
        PrintLabelArray: JsonArray;
    begin
        IsHandled := false;
        OnBeforeSetPrintLabelArray(ResponseToken, IsHandled, LabelsToPrintObject);
        if IsHandled then
            exit(LabelsToPrintObject);

        for ArrayCount := 0 to ResponseToken.AsArray().Count - 1 do begin
            Clear(pieceResponsesToken);
            Clear(PackageDocuments);
            Clear(PackageDocumentsToken);
            Clear(LabelToken);
            ResponseToken.AsArray().Get(ArrayCount, pieceResponsesToken);
            pieceResponsesToken.AsObject().Get('packageDocuments', PackageDocuments);
            PackageDocuments.AsArray().Get(0, PackageDocumentsToken);
            PackageDocumentsToken.AsObject.Get('encodedLabel', EncodedLabelToken);
            LabelToken.Add('EncodedLabel', EncodedLabelToken);
            LabelsToPrint.Add(LabelToken);
        end;
        LabelsToPrintObject.Add('labels', LabelsToPrint);
        if FedexSetup.Find('-') then begin
            LabelsToPrintObject.Add('labelStockType', Format(FedexSetup.LabelStockType));
            LabelsToPrintObject.Add('imageType', Format(FedexSetup.ImageType));
            LabelsToPrintObject.Add('salesOrderNumber', SalesShipmentHeader."Order No.");
        end;
        OnAfterSetPrintLabelArray(LabelsToPrintObject);
        exit(LabelsToPrintObject);
    end;

    procedure SetTrackingNumberFromResponse(HttpResponseMessage: HttpResponseMessage; SalesShipmentHeader: Record "Sales Shipment Header")
    var
        JsonResponse: JsonObject;
        JsonResponseAsText: Text;
        JsonToken: JsonToken;
        JsonToken1: JsonToken;
        JsonToken2: JsonToken;
        JsonToken3: JsonToken;
        TrackingNumber: Text;
        SalesOrderHeader: Record "Sales Header";
        OrderNo: Code[20];
        ShipmentHeader: Record "Sales Shipment Header";
    begin
        if not HttpResponseMessage.IsSuccessStatusCode() then
            exit;

        // Parse the JSON response
        if HttpResponseMessage.Content().ReadAs(JsonResponseAsText) then begin
            // Adapt the below path based on your actual JSON structure
            JsonResponse.ReadFrom(JsonResponseAsText);
            if not JsonResponse.Get('output', JsonToken) then
                exit;

            if not JsonToken.AsObject().Get('transactionShipments', JsonToken1) then
                exit;

            if not JsonToken1.AsArray().Get(0, JsonToken2) then
                exit;

            if not JsonToken2.AsObject().Get('masterTrackingNumber', JsonToken3) then
                exit;

            TrackingNumber := JsonToken3.AsValue().AsText();

            OrderNo := SalesShipmentHeader."Order No.";

            ShipmentHeader.Copy(SalesShipmentHeader);
            ShipmentHeader.SetFilter("Order No.", OrderNo);
            ShipmentHeader.FIndSet();
            repeat
                ShipmentHeader."Shipping Agent Code" := SalesShipmentHeader."Shipping Agent Code";
                ShipmentHeader."Shipping Agent Service Code" := SalesShipmentHeader."Shipping Agent Service Code";
                ShipmentHeader."Fedex Tracking No." := TrackingNumber;
                ShipmentHeader."Label Status" := ShipmentHeader."Label Status"::Generated;
                ShipmentHeader.Modify();
            until ShipmentHeader.Next() <= 0;

            if SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, OrderNo) then begin
                SalesOrderHeader."Fedex Tracking No." := TrackingNumber;
                SalesOrderHeader."Label Status" := SalesOrderHeader."Label Status"::Generated;
                SalesOrderHeader.Modify();
            end;
        end;
    end;

    var
        PrintLabelArray: JsonObject;
        ResponseData: HttpResponseMessage;
        PieceArrayToken: JsonToken;
        SalesShipmentHeader: Record "Sales Shipment Header";
        FedexSetup: Record "Fedex Setup";
        PrintLabels: Codeunit "Printer - Print Labels";
        IsHandled: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreationResponseHandler(var ResponseData: HttpResponseMessage; var IsHandled: Boolean; var Token: JsonToken)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPrintLabelArray(var ResponseToken: JsonToken; var IsHandled: Boolean; var LabelsToPrintObject: JsonObject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrintLabelArray(var LabelsToPrintObject: JsonObject);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreationResponseHandler(var Token: JsonToken)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingNumberFromResponse(var ResponseData: HttpResponseMessage; var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

}