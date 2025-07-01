table 50100 "Fedex Setup"
{
    DataClassification = CustomerContent;
    Caption = 'Fedex Setup';
    Permissions = tabledata "Fedex Setup" = RIMD;

    fields
    {
        field(1; Code; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Code';

        }
        field(2; URI; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(3; Grant_Type; Enum "Fedex Grant Types")
        {
            DataClassification = ToBeClassified;
            Caption = 'Grant Type';
            ToolTip = 'Type of customer.';
        }

        field(4; Client_id; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Client Id';
            ToolTip = 'Retrieve Client Id (API Key) from the fedex developer portal.';
            ExtendedDatatype = Masked;
        }

        field(5; Client_Secret; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Client Secret';
            ToolTip = 'Retreive the Client Secret from the fedex developer portal.';
            ExtendedDatatype = Masked;
        }

        field(6; Access_Token; Text[1500])
        {
            DataClassification = ToBeClassified;
            Caption = 'Access Token';
            ToolTip = 'This is an encrypted OAuth token used to authenticate your API requests. Use it in the authorization header of your API requests.';
            ExtendedDatatype = Masked;
            Editable = true;
        }

        field(7; Token_Type; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Token Type';
            ToolTip = 'This is a token type.';
            Editable = true;
        }

        field(8; Token_Expiary; DateTime)
        {
            DataClassification = ToBeClassified;
            Caption = 'Expires';
            ToolTip = 'Indicates the token expiration time.';
            Editable = true;
        }

        field(9; Scope; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Scope';
            ToolTip = 'Indicates the scope of authorization provided to the consumer.';
            Editable = true;
        }

        field(10; PickUpType; Enum "Fedex PickUp Types")
        {
            DataClassification = ToBeClassified;
            Caption = 'Pick Up Type';
            ToolTip = 'Indicates if shipment is being dropped off at a FedEx location or being picked up by FedEx or if it''s a regularly scheduled pickup for this shipment.';
            Editable = true;
        }

        field(11; LabelStockType; Enum "Fedex Label Sizes")
        {
            DataClassification = ToBeClassified;
            Caption = 'Label Stock Type';
            ToolTip = 'Label Stock Type.';
            Editable = true;
        }

        field(12; ImageType; Enum "Fedex Image Types")
        {
            DataClassification = ToBeClassified;
            Caption = 'Image Type';
            ToolTip = 'Specifies the image type of this shipping document.';
            Editable = true;
        }

        field(13; AccountNumber; Text[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Account Number';
            ToolTip = 'Your account number.';
            Editable = true;
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}