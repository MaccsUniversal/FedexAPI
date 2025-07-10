codeunit 50103 "Fedex - Create Rsp. Handler"
{
    Permissions = tabledata "Sales Shipment Header" = M;
    trigger OnRun()
    begin
        PieceArrayToken := responseHandler();
        PrintLabelArray := SetPrintLabelArray(PieceArrayToken);
        FedexPrintLabels.SetReqBody(PrintLabelArray);
        FedexPrintLabels.Run();
        SetTrackingNumberFromResponse(ResponseData, SalesShipmentHeader);
    end;

    procedure SetResponseData(Response: HttpResponseMessage)
    begin
        ResponseData := Response;
    end;

    procedure SetShipmentHeader(ShipmentHeader: Record "Sales Shipment Header")
    begin
        SalesShipmentHeader := ShipmentHeader;
    end;

    local procedure responseHandler() ArrayToken: JsonToken
    var
        ResponseObjectAsText: Text;
        ResponseObj: JsonObject;
        OutputToken: JsonToken;
        transactionShipmentsToken: JsonToken;
        transactionShipments0: JsonToken;
        PackageDocuments: JsonToken;
        PackageDocumentsToken: JsonToken;
    begin
        ResponseData.Content.ReadAs(ResponseObjectAsText);
        ResponseObj.ReadFrom(ResponseObjectAsText);
        ResponseObj.Get('output', OutputToken);
        OutputToken.AsObject().Get('transactionShipments', transactionShipmentsToken);
        transactionShipmentsToken.AsArray().Get(0, transactionShipments0);
        transactionShipments0.AsObject().Get('pieceResponses', ArrayToken);
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

            SalesShipmentHeader."Package Tracking No." := TrackingNumber;
            SalesShipmentHeader.Modify();

            if SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, OrderNo) then begin
                SalesOrderHeader."Package Tracking No." := TrackingNumber;
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
        FedexPrintLabels: Codeunit "Fedex - Print Labels";

}