Cost Per Support template format
1, This file includes all the possible media mix from curve file.
2, Only 'cps' column is editable. Please DON'T touch any other columns.
3, Missing values are not allowed in 'cps' column.
4, The values in 'cps' column must be positive number.

Constraint template format
1, This template needs to use upload_lookup.csv to fill.
2, The value of each '..._id' column can be multiple items from the same '..._id' column of upload_lookup.csv. If there are multiple items, please ONLY USE COMMA as delimiter. For example, 'TV,Paid Search'.
3, Missing values are not allowed in '..._id' columns.
4, sp_min or sp_max cannot be less than incremental search pace.
5, sp_max and sp_min cannot be both missing.
6, date_start and date_end format: mm/dd/yyyy.
7, Missing values are not allowed in date_start and date_end columns.
8, Date range must be in between 7 - 366 days.
9, sp_min <= sp_max

Plan template format
1, This template needs to use upload_lookup.csv to fill.
2, The value of each '..._id' column can be multiple items from the same '..._id' column of upload_lookup.csv. If there are multiple items, please ONLY USE COMMA as delimiter. For example, 'TV,Paid Search'.
3, Missing values are not allowed in '..._id' columns.
4, sp_plan cannot be less than incremental search pace.
5, sp_plan cannot be missing.
6, date_start and date_end format: mm/dd/yyyy.
7, Missing values are not allowed in date_start and date_end columns.
8, Date range must be in between 7 - 366 days.

Event template format
1, This template needs to use upload_lookup.csv to fill.
2, The value of each '..._id' column can be multiple items from the same '..._id' column of upload_lookup.csv. If there are multiple items, please ONLY USE COMMA as delimiter. For example, 'TV,Paid Search'.
3, Missing values are not allowed in any column.
4, date_start and date_end format: mm/dd/yyyy.
5, Missing values are not allowed in date_start and date_end columns.
6, Date range must be in between 7 - 366 days.

