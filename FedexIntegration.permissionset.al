namespace Fedex_Integration_Permission_Set;
using System.Security.AccessControl;
using Microsoft.Inventory.Item;

permissionset 99003 Fedex_Integration
{
    IncludedPermissionSets = "D365 BUS FULL ACCESS", "D365 READ", "D365 BASIC";
    Assignable = true;
    Permissions = tabledata "Fedex Bundle Items" = RIMD,
        tabledata "Fedex Setup" = RIMD,
        table "Fedex Bundle Items" = X,
        table "Fedex Setup" = X,
        codeunit "Fedex - Cancel Labels" = X,
        codeunit "Fedex - Create Label" = X,
        codeunit "Fedex Authorization" = X,
        codeunit "Fedex Bundle Items" = X,
        codeunit "Fedex Email Notifications" = X,
        codeunit "Fedex Http Error Handler" = X,
        codeunit "Fedex Setup Init" = X,
        codeunit "Label Cancellation Response" = X,
        codeunit "Label Creation Response" = X,
        codeunit "Printer - Clear Directory" = X,
        codeunit "Printer - Create Directory" = X,
        codeunit "Printer - Print Labels" = X,
        page "Fedex - Bundle Items" = X,
        page "Fedex Setup Page" = X;
}