codeunit 50100 FedexAuthorization
{
    var
        HttpClient: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        Response: HttpResponseMessage;
        FedexSetup: Record "Fedex Setup";

    trigger OnRun()
    begin
        RequestToken();
    end;

    procedure RequestToken(): HttpResponseMessage
    var
        URIPath: Text;
        GrantType: Text;
        ClientId: Text;
        ClientSecret: Text;
        Payload: Text;
        IsSuccessful: Boolean;
        ClientIdError: Label 'Please provide a client id.';
        ClientSecretError: Label 'Please provide a client secret.';
        FedexSetupError: Label 'Complete Fedex API setup to retrive access token.';
        IsHandled: Boolean;
        Sent: Boolean;
    begin
        if not FedexSetup.Get('FEDEXAPI') then
            Error(FedexSetupError);
        URIPath := FedexSetup.URI;
        GrantType := FormatGrantType(FedexSetup.Grant_Type);

        if FedexSetup.Client_id = '' then
            Error(ClientIdError);
        IsolatedStorage.Set('ClientId', FedexSetup.Client_id, DataScope::Module);
        IsolatedStorage.Get('ClientId', DataScope::Module, ClientId);

        if FedexSetup.Client_Secret = '' then
            Error(ClientSecretError);
        IsolatedStorage.Set('ClientSecret', FedexSetup.Client_Secret, DataScope::Module);
        IsolatedStorage.Get('ClientSecret', DataScope::Module, ClientSecret);

        IsHandled := false;
        OnBeforeSetPayload(Payload, IsHandled);
        if not IsHandled then
            Payload := 'grant_type=' + Format(GrantType) + '&client_id=' + ClientId + '&client_secret=' + ClientSecret;

        Content.WriteFrom(Payload);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        OnBeforeAddContentHeaders(ContentHeaders);
        ContentHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');
        HttpClient.SetBaseAddress(URIPath);
        Sent := false;
        OnBeforeHttpClientCall(IsSuccessful, HttpClient, Response, Content, Sent);
        if not Sent then
            IsSuccessful := HttpClient.Post('/oauth/token', Content, Response);
        OnAfterHttpClientCall(IsSuccessful);
        if Response.HttpStatusCode <> 200 then
            ErrorResponseMessage(Response.HttpStatusCode);

        Message('Succesfully completed authorization call. Access Token retreived. Status=%1', Response.ReasonPhrase);

        ResponseHandler(Response);
        exit;
    end;

    local procedure ResponseHandler(var Response: HttpResponseMessage)
    var
        JsonObject: JsonObject;
        JsonToken1: JsonToken;
        JsonToken2: JsonToken;
        JsonToken3: JsonToken;
        JsonToken4: JsonToken;
        ResponseText: Text;
        AccessTokenResponse: Text;
        TokenTypeResponse: Text;
        ExpiresInResponse: Text;
        ScopeResponse: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResponseHandler(Response, IsHandled);
        if IsHandled then
            exit;

        Response.Content.ReadAs(ResponseText);
        JsonObject.ReadFrom(ResponseText);
        JsonObject.Get('access_token', JsonToken1);
        JsonObject.Get('token_type', JsonToken2);
        JsonObject.Get('expires_in', JsonToken3);
        JsonObject.Get('scope', JsonToken4);
        if not FedexSetup.Get('FEDEXAPI') then
            Error('Complete Fedex API setup to retrive access token.');

        JsonToken1.WriteTo(AccessTokenResponse);
        StoreAccessToken(AccessTokenResponse);
        JsonToken2.WriteTo(TokenTypeResponse);
        FedexSetup.Token_Type := TokenTypeResponse.Replace('"', '');
        JsonToken3.WriteTo(ExpiresInResponse);
        FedexSetup.Token_Expiary := CalculateExpiaryTime(ExpiresInResponse);
        JsonToken4.WriteTo(ScopeResponse);
        FedexSetup.Scope := ScopeResponse.Replace('"', '');

        OnAfterResponseHandler(JsonObject);
        FedexSetup.Modify();

    end;

    local procedure FormatGrantType(GrantType: Enum "Fedex Grant Types"): Text
    var
        GrantTypeInText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatGrantType(GrantType, GrantTypeInText, IsHandled);
        if IsHandled then
            exit(GrantTypeInText);

        case GrantType of
            "Fedex Grant Types"::client_credentials:
                GrantTypeInText := 'client_credentials';
            "Fedex Grant Types"::client_pc_credentials:
                GrantTypeInText := 'client_pc_credentials';
            "Fedex Grant Types"::crp_credentials:
                GrantTypeInText := 'crp_credentials';
            else
                Error('Incorrect or no grant type provided.');
        end;
        OnAfterFormatGrantType(GrantTypeInText);
        exit(GrantTypeInText);
    end;

    local procedure ErrorResponseMessage(ResponseHttpCode: Integer)
    var
        Unauthorized: Label 'The given client credentials were not valid. Please modify your request and try again.';
        UnauthorizedCode: Label '401:NOT.AUTHORIZED.ERROR';
        Failure: Label 'We encountered an unexpected error and are working to resolve the issue. We apologize for any inconvenience. Please check back at a later time.';
        FailureCode: Label '500:INTERNAL.SERVER.ERROR';
        ServiceUnavailable: Label 'The service is currently unavailable and we are working to resolve the issue. We apologize for any inconvenience. Please check back at a later time.';
        ServiceUnavailableCode: Label '503:SERVICE.UNAVAILABLE.ERROR';
        ErrorInfo: ErrorInfo;
        ErrorType: ErrorType;
    begin
        case ResponseHttpCode of
            401:
                begin
                    ErrorInfo.ErrorType(ErrorType::Client);
                    ErrorInfo.Title := UnauthorizedCode;
                    ErrorInfo.Message(Unauthorized);
                    ErrorInfo.DetailedMessage(Unauthorized);
                    Error(ErrorInfo);
                end;
            500:
                begin
                    ErrorInfo.ErrorType(ErrorType::Client);
                    ErrorInfo.Title(FailureCode);
                    ErrorInfo.Message(Failure);
                    ErrorInfo.DetailedMessage(Failure);
                    Error(ErrorInfo);
                end;
            503:
                begin
                    ErrorInfo.ErrorType(ErrorType::Client);
                    ErrorInfo.Title := ServiceUnavailableCode;
                    ErrorInfo.Message(ServiceUnavailable);
                    ErrorInfo.DetailedMessage(ServiceUnavailable);
                    Error(ErrorInfo);
                end;
        end;
    end;

    local procedure StoreAccessToken(var AccessToken: Text)
    begin
        AccessToken := AccessToken.Replace('"', '');
        IsolatedStorage.Set('AccessToken', AccessToken, DataScope::Module);
        IsolatedStorage.Get('AccessToken', DataScope::Module, FedexSetup.Access_Token);
    end;

    local procedure CalculateExpiaryTime(var ExpiaryTime: Text): DateTime
    var
        TimeValue: DateTime;
        ExpiaryTimeInteger: Integer;
        Duration: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateExpiaryTime(ExpiaryTime, IsHandled, TimeValue);
        if IsHandled then
            exit(TimeValue);

        Evaluate(ExpiaryTimeInteger, ExpiaryTime);
        Duration := 1000 * 60 * (Round(ExpiaryTimeInteger / 60));
        TimeValue := CurrentDateTime + Duration;
        OnAfterCalculateExpiaryTime(TimeValue);
        exit(TimeValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHttpClientCall(var IsSuccessful: Boolean; var HttpClient: HttpClient; var Response: HttpResponseMessage; var Content: HttpContent; var Sent: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddContentHeaders(var ContentHeaders: HttpHeaders)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPayload(var Payload: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatGrantType(GrantType: Enum "Fedex Grant Types"; var GrantTypeInText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateExpiaryTime(ExpiaryTime: Text; var IsHandled: Boolean; var DateTimeRef: DateTime)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResponsehandler(var ResponseMsg: HttpResponseMessage; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHttpClientCall(var IsSuccessful: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFormatGrantType(var GrantTypeIntext: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateExpiaryTime(var TimeValue: DateTime)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResponseHandler(var JsonObj: JsonObject)
    begin
    end;

}