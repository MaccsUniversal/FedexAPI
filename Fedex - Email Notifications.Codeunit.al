codeunit 50112 "Fedex Email Notifications"
{
    procedure ToggleNotifications(ContactName: Text; EmailAddress: Text) Enabled: Boolean;
    begin
        if FedexSetup.Find('-') then begin
            FedexSetup.FindSet();
            Enabled := FedexSetup.EnableEmailNotifications;
        end;
        if Enabled then
            NotificationObj := EmailNotificationObject(ContactName, EmailAddress);
        exit(Enabled);
    end;

    procedure GetEmailNotificationObject(): JsonObject
    begin
        exit(NotificationObj);
    end;

    local procedure EmailNotificationObject(ContactName: Text; EmailAddress: Text) EmailNotificationDetail: JsonObject
    var
        EmailNotificationRecipients: JsonArray;
        EmailNotificationRecipientToken: JsonObject;
        NotificationEventType: JsonArray;
    begin
        if not FedexSetup.Find('-') then
            exit;
        FedexSetup.FindSet();
        EmailNotificationRecipientToken.Add('name', ContactName);
        EmailNotificationRecipientToken.Add('emailNotificationRecipientType', 'RECIPIENT');
        EmailNotificationRecipientToken.Add('emailAddress', EmailAddress);
        EmailNotificationRecipientToken.Add('notificationFormatType', 'HTML');
        EmailNotificationRecipientToken.Add('notificationType', 'EMAIL');
        EmailNotificationRecipientToken.Add('locale', 'en_US');
        NotificationEventType.Add('ON_SHIPMENT');
        NotificationEventType.Add('ON_EXCEPTION');
        NotificationEventType.Add('ON_ESTIMATED_DELIVERY');
        NotificationEventType.Add('ON_DELIVERY');
        EmailNotificationRecipientToken.Add('notificationEventType', NotificationEventType);
        EmailNotificationRecipients.Add(EmailNotificationRecipientToken);
        EmailNotificationDetail.Add('aggregationType', 'PER_SHIPMENT');
        EmailNotificationDetail.Add('emailNotificationRecipients', EmailNotificationRecipients);
        EmailNotificationDetail.Add('personalMessage', FedexSetup.PersonalMessage);
        exit(EmailNotificationDetail);
    end;

    var
        FedexSetup: Record "Fedex Setup";
        NotificationObj: JsonObject;
}