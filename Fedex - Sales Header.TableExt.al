tableextension 99011 "Fedex - Sales Header" extends "Sales Header"
{
    fields
    {
        field(1000; "Fedex Tracking No."; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Fedex Tarcking No.';
        }

        field(1001; "Label Status"; Enum "Fedex Label Status")
        {
            DataClassification = ToBeClassified;
            Caption = 'Fedex Label Status';
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }
}