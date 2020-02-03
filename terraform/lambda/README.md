# Lambda
## ES Cleanup
Schedule to run every day at 10:00 AM.
Finds all indices from Arcanebet ES and deletes ones that are older than 14 DAYS.
Indices must be suffixed with date in format of `%Y%m%d`, example: `20201128`.