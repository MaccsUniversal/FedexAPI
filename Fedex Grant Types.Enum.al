enum 50100 "Fedex Grant Types"
{
    Extensible = true;

    value(0; client_credentials)
    {
        Caption = 'Client Credentials';
    }

    value(1; crp_credentials)
    {
        Caption = 'CRP Credentials';
    }

    value(2; client_pc_credentials)
    {
        Caption = 'Client PC Credentials';
    }

}