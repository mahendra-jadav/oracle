with tab_tables as
( select json_object ( KEY 'owner' VALUE t.owner
                     , KEY 'table_name' VALUE t.table_name
                     ) as tables
    from all_tables t
   where table_name='<table-name>'
     and owner='<owner>'
), tab_table_columns as
( select JSON_ARRAYAGG( json_object ( KEY 'owner' VALUE tc.owner
                                    , KEY 'table_name' VALUE tc.table_name
                                    , KEY 'column_name' VALUE tc.column_name
                                    , KEY 'data_type' VALUE tc.data_type
                                    , KEY 'data_length' VALUE tc.data_length
                                    , KEY 'data_precision' VALUE tc.data_precision
                                    , KEY 'nullable' VALUE tc.nullable
                                    , KEY 'column_id' VALUE tc.column_id
                                    ) 
                      ) as table_columns
    from all_tab_columns tc
   where table_name='<table-name>'
     and owner='<owner>'
), tab_constraints as
( select JSON_ARRAYAGG (
       json_object( KEY 'table_name'        VALUE c.table_name
                  , KEY 'constraint_name'   VALUE c.constraint_name
                  , KEY 'constraint_type'   VALUE c.constraint_type
                  , KEY 'column_name'       VALUE cc.column_name
                  , KEY 'position'          VALUE cc.position
                  , KEY 'r_owner'           VALUE c.r_owner
                  , KEY 'r_constraint_name' VALUE c.r_constraint_name
                  , KEY 'r_table_name'      VALUE (select table_name
                                                     from all_constraints b
                                                    where b.owner = c.r_owner
                                                      and b.constraint_name = c.r_constraint_name
                                                  ) 
                  , KEY 'r_column_name'     VALUE (select bc.column_name
                                                     from all_constraints b inner join all_cons_columns bc
                                                       on (bc.constraint_name = b.constraint_name and
                                                           b.owner = bc.owner)
                                                    where b.owner = c.r_owner
                                                      and b.constraint_name = c.r_constraint_name
                                                      and bc.position = cc.position
                                                  ) 
                  ) ) as constraints
  from all_constraints c inner join all_cons_columns cc
    on (cc.constraint_name = c.constraint_name and
        cc.owner           = c.owner)
 where c.table_name='BUCKETS'
   and c.owner='<owner>'
   and c.constraint_type in ('P','U','R')
   and c.status='ENABLED'
 order by c.constraint_name, cc.position
)
select JSON_OBJECT( KEY 'tables' VALUE t.tables
                  , KEY 'table_columns' VALUE tc.table_columns
                  , KEY 'constraints' VALUE c.constraints
                  )
  from tab_tables t cross join tab_table_columns tc
                    cross join tab_constraints c
