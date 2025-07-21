table 50103 "Fedex Bundle Items"
{
    DataClassification = ToBeClassified;
    Caption = 'Bundle Items';

    fields
    {
        field(1; "FED Item No."; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Item No.';
            TableRelation = Item;
        }

        field(2; "Description"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Description';
            Editable = false;
        }

        field(3; "Pcs. Per Parcel"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Pcs. Per Parcel';
        }
    }

    keys
    {
        key(Key1; "FED Item No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

}