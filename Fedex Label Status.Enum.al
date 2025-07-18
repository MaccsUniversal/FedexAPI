enum 50105 "Fedex Label Status"
{
    Extensible = true;

    value(0; None)
    {
        Caption = 'None';
    }

    value(1; Generated)
    {
        Caption = 'Labels Generated';
    }

    value(2; Cancelled)
    {
        Caption = 'Labels Cancelled';
    }
}