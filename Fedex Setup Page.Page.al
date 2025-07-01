page 50100 "Fedex Setup Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Fedex Setup";
    DelayedInsert = true;
    Permissions = tabledata "Fedex Setup" = RIMD;
    DeleteAllowed = false;
    ModifyAllowed = true;
    InsertAllowed = false;
    Editable = true;

    layout
    {
        area(Content)
        {
            group("OAuth Credentials")
            {
                group("Token Request")
                {
                    Caption = 'Credentials';
                    field(URI; Rec.URI)
                    {
                        Caption = 'URI';
                        ToolTip = 'URI Path.';
                        ApplicationArea = All;
                    }
                    field(Grant_Type; Rec.Grant_Type)
                    {
                        Caption = 'Grant Type';
                        ApplicationArea = All;
                    }

                    field(Client_id; Rec.Client_id)
                    {
                        Caption = 'Client Id';
                        ApplicationArea = All;
                    }

                    field(Client_Secret; Rec.Client_Secret)
                    {
                        Caption = 'Client Secret';
                        ApplicationArea = All;
                    }
                }

                group("AccessToken")
                {
                    Caption = 'Access Token';
                    field(Access_Token; Rec.Access_Token)
                    {
                        Caption = 'Access Token';
                        ApplicationArea = All;
                        Enabled = false;
                    }

                    field(Token_Type; Rec.Token_Type)
                    {
                        Caption = 'Token Type';
                        ApplicationArea = All;
                        Enabled = false;
                    }

                    field(Token_Expiary; Rec.Token_Expiary)
                    {
                        Caption = 'Expires';
                        ApplicationArea = All;
                        Enabled = false;
                    }

                    field(Scope; Rec.Scope)
                    {
                        Caption = 'Scope';
                        ApplicationArea = All;
                        Enabled = false;
                    }

                }

                group(LabelCreation)
                {
                    Caption = 'Label Creation';

                    field(AccountNumber; Rec.AccountNumber)
                    {
                        Caption = 'Account Number';
                        ApplicationArea = All;
                        Enabled = true;
                    }

                    field(PickUpType; Rec.PickUpType)
                    {
                        Caption = 'Pick Up Type';
                        ApplicationArea = All;
                        Enabled = true;
                    }

                    field(LabelStockType; Rec.LabelStockType)
                    {
                        Caption = 'Label Stock Type';
                        ApplicationArea = All;
                        Enabled = true;
                    }

                    field(ImageType; Rec.ImageType)
                    {
                        Caption = 'Image Type';
                        ApplicationArea = All;
                        Enabled = true;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                var
                    FedexAuth: Codeunit FedexAuthorization;
                begin
                    FedexAuth.Run();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        FedexSetupInit: Codeunit "Fedex Setup Init";
    begin
        FedexSetupInit.Init();
    end;


}