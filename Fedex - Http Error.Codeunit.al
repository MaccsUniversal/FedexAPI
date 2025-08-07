codeunit 99015 "Fedex Http Error Handler"
{
    procedure HandleHttpError(HttpResponseMessage: HttpResponseMessage)
    var
        StatusCode: Integer;
        ReasonPhrase: Text;
        ErrorTypeDescription: Text;
        FurtherDetails: Text;
    begin
        if HttpResponseMessage.IsSuccessStatusCode() then
            exit;

        HttpResponseMessage.Content.ReadAs(FurtherDetails);
        StatusCode := HttpResponseMessage.HttpStatusCode();
        ReasonPhrase := HttpResponseMessage.ReasonPhrase();
        ErrorTypeDescription := GetHttpErrorDescription(StatusCode);

        Error(
            'HTTP Error Occurred:\Status Code: %1\Reason: %2\Message: %3 \Detailed message: %4',
            StatusCode, ReasonPhrase, ErrorTypeDescription, FurtherDetails
        );
    end;

    local procedure GetHttpErrorDescription(StatusCode: Integer): Text
    begin
        case StatusCode of
            400:
                exit('Bad Request - The server could not understand the request due to invalid syntax.');
            401:
                exit('Unauthorized - Authentication is required and has failed or not been provided.');
            403:
                exit('Forbidden - You do not have permission to access this resource.');
            404:
                exit('Not Found - The requested resource could not be found.');
            405:
                exit('Method Not Allowed - The request method is not supported for this resource.');
            408:
                exit('Request Timeout - The server timed out waiting for the request.');
            500:
                exit('Internal Server Error - A generic error occurred on the server.');
            502:
                exit('Bad Gateway - Received an invalid response from the upstream server.');
            503:
                exit('Service Unavailable - The server is not ready to handle the request.');
            504:
                exit('Gateway Timeout - The server did not receive a timely response.');
            else
                exit('An unexpected HTTP error occurred. Please refer to the documentation or error logs for more detail.');
        end;
    end;

    var
        myInt: Integer;
}