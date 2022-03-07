    
with tab_tables as
( select JSON_OBJECT( 'owner', t.table_schema
                    , 'table_name', t.table_name
	  			    ) as tables
    from information_schema.tables t
   where table_name='test_table'
     and table_schema='application'
), tab_table_columns as
( select JSON_ARRAYAGG(
         JSON_OBJECT( 'owner',table_schema
                    , 'table_name', table_name
                    , 'column_name', column_name
                    , 'data_type', data_type
                    , 'data_length', COALESCE(numeric_precision, character_maximum_length)
                    , 'numeric_scale', numeric_scale
                    , 'nullable', case when is_nullable = 'YES' then 'Y' else 'N' end 
                    , 'column_id',ordinal_position
                    ) ) as table_columns
    from information_schema.columns
   where table_name='test_table'
     and table_schema='application'
   order by ordinal_position
), tab_constraints as
( select JSON_ARRAYAGG(
         json_object( 'table_name', c.table_name
                    , 'constraint_name', c.constraint_name
                    , 'constraint_type', case when c.constraint_type='PRIMARY KEY' then 'P'
                                              when c.constraint_type='UNIQUE' then 'U'
                                              when c.constraint_type='FOREIGN KEY' then 'F'
                                              else null
										 end
					, 'column_name', cc.column_name
                    , 'position', cc.ordinal_position
                    , 'r_owner', cc.referenced_table_schema
                    , 'r_constraint_name',null
                    , 'r_table_name', cc.referenced_table_name
                    , 'r_column_name', cc.referenced_column_name
                    )) as constraints
    from INFORMATION_SCHEMA.TABLE_CONSTRAINTS c inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE cc
      on (c.table_schema = cc.table_schema and
          c.table_name = cc.table_name and
          c.constraint_name = cc.constraint_name
	     )
   where c.table_name='test_table'
     and c.table_schema='application'
     and c.constraint_type in ('PRIMARY KEY','FOREIGN KEY','UNIQUE') 
)
select json_object( 'tables'
                  , t.tables
                  , 'table_columns'
                  , tc.table_columns
                  , 'constraints'
                  , c.constraints
                  )
  from tab_tables t cross join tab_table_columns tc
                    cross join tab_constraints c
