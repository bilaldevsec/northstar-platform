# Phase F & G KQL Queries
1. Privilege Escalation: `AzureActivity | where OperationNameValue =~ "MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE" and ActivityStatusValue == "Success"`
2. Network Exposure: `AzureActivity | where OperationNameValue =~ "MICROSOFT.NETWORK/NETWORKSECURITYGROUPS/SECURITYRULES/WRITE" and tostring(Properties) has "0.0.0.0/0"`
3. Honeytoken Read: `AzureDiagnostics | where ResourceProvider == "MICROSOFT.KEYVAULT" and requestUri_s has "canary-"`
