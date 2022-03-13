with tab_tables as
( select json_build_object( 'owner',t.table_schema
                          , 'table_name',t.table_name
						  ) as tables
    from information_schema.tables t
   where table_name='postgres_example2'
     and table_schema='public'
), tab_table_columns as
( select ARRAY_AGG(
            json_build_object( 'owner',table_schema
                             , 'table_name', table_name
                             , 'column_name', column_name
                             , 'data_type', data_type
                             , 'data_length', COALESCE(numeric_precision, character_maximum_length)
                             , 'numeric_scale', numeric_scale
                             , 'nullable', case when is_nullable = 'YES' then 'Y' else 'N' end 
                             , 'column_id',ordinal_position
                             ) 
         ) as table_columns
    from information_schema.columns
   where table_name='postgres_example2'
     and table_schema='public'
), tab_constraints as
( select ARRAY_AGG(
            json_build_object( 'table_name', c.table_name
                             , 'constraint_name', c.constraint_name
                             , 'constraint_type', case when c.constraint_type='PRIMARY KEY' then 'P'
                                                  when c.constraint_type='UNIQUE' then 'U'
                                                  when c.constraint_type='FOREIGN KEY' then 'F'
                                                  else null
							     			      end
					         , 'column_name', cc.column_name
                             , 'position', cc.ordinal_position
                             , 'r_owner', ( select b.unique_constraint_schema
                                              from INFORMATION_SCHEMA.referential_constraints b
                                             where b.constraint_name = c.constraint_name
									   	       and b.constraint_schema = c.constraint_schema
									      )
                             , 'r_constraint_name',( select b.unique_constraint_name
                                                       from INFORMATION_SCHEMA.referential_constraints b
                                                      where b.constraint_name = c.constraint_name
										                and b.constraint_schema = c.constraint_schema
									               )
                             , 'r_table_name', (select tc.table_name
                                                  from INFORMATION_SCHEMA.referential_constraints b inner join INFORMATION_SCHEMA.table_constraints tc 
											        on (tc.constraint_name = b.unique_constraint_name and
													    tc.constraint_schema = b.unique_constraint_schema)
                                                 where b.constraint_name = c.constraint_name
										           and b.constraint_schema = c.constraint_schema
											   )
                             , 'r_column_name', (select ku.column_name
                                                   from INFORMATION_SCHEMA.referential_constraints b inner join INFORMATION_SCHEMA.table_constraints tc 
								   			         on (tc.constraint_name = b.unique_constraint_name and
												 	     tc.constraint_schema = b.unique_constraint_schema) inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE ku
											         on (tc.table_schema     = ku.table_schema         and
                                                         tc.table_name       = ku.table_name           and
                                                         tc.constraint_name  = ku.constraint_name      and
													     cc.position_in_unique_constraint = ku.ordinal_position
	                                                    )
                                                  where b.constraint_name = c.constraint_name
										            and b.constraint_schema = c.constraint_schema
											    )
                          )) as constraints
    from INFORMATION_SCHEMA.TABLE_CONSTRAINTS c inner join INFORMATION_SCHEMA.KEY_COLUMN_USAGE cc
      on ( c.table_schema = cc.table_schema and
           c.table_name = cc.table_name     and
           c.constraint_name = cc.constraint_name
	     )
   where c.table_name='postgres_example2'
     and c.table_schema='public'
     and c.constraint_type in ('PRIMARY KEY','FOREIGN KEY','UNIQUE') 
)
select json_build_object( 'tables'
                        , t.tables
                        , 'table_columns'
                        , tc.table_columns
                        , 'constraints'
                        , c.constraints
                        )
  from tab_tables t cross join tab_table_columns tc
                    cross join tab_constraints c
