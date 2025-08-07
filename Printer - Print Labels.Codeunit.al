codeunit 99021 "Printer - Print Labels"
{
    trigger OnRun()
    begin
        ReqContent := SetContent();
        SendLabelsToPrint(ReqContent);
    end;

    procedure SetReqBody(JsonInput: JsonObject)
    begin
        JsonInput.WriteTo(ReqBody);
    end;

    local procedure SetContent() Content: HttpContent
    var
        ContentHeaders: HttpHeaders;
    begin
        IsHandled := false;
        OnBeforeSetContent(Content, IsHandled);
        if IsHandled then
            exit(Content);
        Content.WriteFrom(ReqBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'application/json');
        OnAfterSetContent(Content);
        exit(Content);
    end;

    local procedure SendLabelsToPrint(Content: HttpContent)
    var
        Path: Text;
        Endpoint: Text;
        ResponseText: Text;
        ResponseObj: JsonObject;
        ResponseToken: JsonToken;
        TokenAsText: Text;
        IsSuccessful: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendLabelsToPrint(Content, IsHandled);
        if IsHandled then
            exit;
        Path := 'https://perch-moral-purely.ngrok-free.app/';
        Endpoint := 'print_labels';
        IsSuccessful := Client.Post(Path + Endpoint, Content, ResponseMessage);
        if not IsSuccessful then begin
            Error('Print Labels Codeunit failed to execute');
        end else begin
            if IsSuccessful then
                FedexHttpErrorHandler.HandleHttpError(ResponseMessage);
        end;

        ResponseMessage.Content.ReadAs(ResponseText);
        ResponseObj.ReadFrom(ResponseText);
        ResponseObj.Get('message', ResponseToken);
        ResponseToken.WriteTo(TokenAsText);
        TokenAsText := TokenAsText.Replace('"', '');
        OnAfterSendLabelsToPrint(TokenAsText);
        Message(TokenAsText);
    end;

    var
        Client: HttpClient;
        ReqContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        ReqBody: Text;
        ResponseText: Text;
        JsonBody: JsonObject;
        FedexSetup: Record "Fedex Setup";
        FedexHttpErrorHandler: Codeunit "Fedex Http Error Handler";
        IsHandled: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendLabelsToPrint(var Content: HttpContent; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetContent(var Content: HttpContent; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetContent(var Content: HttpContent)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendLabelsToPrint(var TokenAsText: Text)
    begin
    end;

}