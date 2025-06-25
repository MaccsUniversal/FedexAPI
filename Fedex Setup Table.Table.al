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
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}