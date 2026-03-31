import asyncio
import asyncpg
import json
import os
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))

async def extract_schema():
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise ValueError("DATABASE_URL not set")
    
    conn = await asyncpg.connect(dsn=database_url)
    try:
        schema = {}
        
        # Get all tables
        tables = await conn.fetch("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_type = 'BASE TABLE'
            ORDER BY table_name;
        """)
        
        for table_row in tables:
            table_name = table_row['table_name']
            schema[table_name] = {
                'columns': [],
                'primary_key': [],
                'foreign_keys': [],
                'indexes': [],
                'constraints': [],
                'triggers': []
            }
            
            # Get columns with full details
            columns = await conn.fetch("""
                SELECT 
                    column_name,
                    data_type,
                    udt_name,
                    is_nullable,
                    column_default,
                    character_maximum_length,
                    numeric_precision,
                    numeric_scale,
                    ordinal_position
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = $1
                ORDER BY ordinal_position;
            """, table_name)
            
            for col in columns:
                schema[table_name]['columns'].append({
                    'name': col['column_name'],
                    'data_type': col['data_type'],
                    'udt_name': col['udt_name'],
                    'is_nullable': col['is_nullable'] == 'YES',
                    'default': col['column_default'],
                    'max_length': col['character_maximum_length'],
                    'numeric_precision': col['numeric_precision'],
                    'numeric_scale': col['numeric_scale']
                })
            
            # Get primary keys
            pk_cols = await conn.fetch("""
                SELECT kcu.column_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu 
                    ON tc.constraint_name = kcu.constraint_name
                WHERE tc.constraint_type = 'PRIMARY KEY' 
                AND tc.table_schema = 'public' 
                AND tc.table_name = $1
                ORDER BY kcu.ordinal_position;
            """, table_name)
            schema[table_name]['primary_key'] = [row['column_name'] for row in pk_cols]
            
            # Get foreign keys
            fks = await conn.fetch("""
                SELECT
                    kcu.column_name AS foreign_column,
                    ccu.table_name AS referenced_table,
                    ccu.column_name AS referenced_column,
                    rc.constraint_name,
                    rc.update_rule,
                    rc.delete_rule
                FROM information_schema.referential_constraints rc
                JOIN information_schema.key_column_usage kcu 
                    ON rc.constraint_name = kcu.constraint_name
                JOIN information_schema.constraint_column_usage ccu 
                    ON rc.unique_constraint_name = ccu.constraint_name
                WHERE rc.constraint_schema = 'public' 
                AND kcu.table_name = $1;
            """, table_name)
            
            for fk in fks:
                schema[table_name]['foreign_keys'].append({
                    'column': fk['foreign_column'],
                    'references_table': fk['referenced_table'],
                    'references_column': fk['referenced_column'],
                    'constraint_name': fk['constraint_name'],
                    'on_update': fk['update_rule'],
                    'on_delete': fk['delete_rule']
                })
            
            # Get indexes (including GIN, GIST, etc.)
            indexes = await conn.fetch("""
                SELECT
                    i.relname AS index_name,
                    ix.indisunique AS is_unique,
                    ix.indisprimary AS is_primary,
                    am.amname AS index_type,
                    pg_get_indexdef(ix.indexrelid) AS index_definition
                FROM pg_index ix
                JOIN pg_class t ON t.oid = ix.indrelid
                JOIN pg_class i ON i.oid = ix.indexrelid
                JOIN pg_namespace n ON n.oid = t.relnamespace
                JOIN pg_am am ON am.oid = i.relam
                WHERE n.nspname = 'public' AND t.relname = $1;
            """, table_name)
            
            for idx in indexes:
                schema[table_name]['indexes'].append({
                    'name': idx['index_name'],
                    'is_unique': idx['is_unique'],
                    'is_primary': idx['is_primary'],
                    'type': idx['index_type'],
                    'definition': idx['index_definition']
                })
            
            # Get check constraints
            checks = await conn.fetch("""
                SELECT
                    tc.constraint_name,
                    cc.check_clause
                FROM information_schema.table_constraints tc
                JOIN information_schema.check_constraints cc 
                    ON tc.constraint_name = cc.constraint_name
                WHERE tc.constraint_type = 'CHECK'
                AND tc.table_schema = 'public'
                AND tc.table_name = $1
                AND cc.constraint_schema = 'public';
            """, table_name)
            
            for check in checks:
                schema[table_name]['constraints'].append({
                    'type': 'CHECK',
                    'name': check['constraint_name'],
                    'clause': check['check_clause']
                })
            
            # Get triggers
            triggers = await conn.fetch("""
                SELECT
                    trigger_name,
                    event_manipulation,
                    event_object_table,
                    action_statement,
                    action_timing
                FROM information_schema.triggers
                WHERE event_object_schema = 'public'
                AND event_object_table = $1;
            """, table_name)
            
            for trigger in triggers:
                schema[table_name]['triggers'].append({
                    'name': trigger['trigger_name'],
                    'event': trigger['event_manipulation'],
                    'timing': trigger['action_timing'],
                    'statement': trigger['action_statement']
                })
        
        # Get views
        views = await conn.fetch("""
            SELECT 
                table_name AS view_name,
                view_definition
            FROM information_schema.views
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        
        schema['_views'] = []
        for view in views:
            schema['_views'].append({
                'name': view['view_name'],
                'definition': view['view_definition']
            })
        
        # Get functions
        functions = await conn.fetch("""
            SELECT
                routine_name,
                data_type AS return_type,
                routine_definition
            FROM information_schema.routines
            WHERE routine_schema = 'public'
            ORDER BY routine_name;
        """)
        
        schema['_functions'] = []
        for func in functions:
            schema['_functions'].append({
                'name': func['routine_name'],
                'return_type': func['return_type'],
                'definition': func['routine_definition']
            })
        
        # Get extensions
        extensions = await conn.fetch("""
            SELECT extname, extversion FROM pg_extension ORDER BY extname;
        """)
        
        schema['_extensions'] = [{'name': ext['extname'], 'version': ext['extversion']} for ext in extensions]
        
        # Print the schema
        print(json.dumps(schema, indent=2, default=str))
        
        # Also save to file
        with open('db_schema_dump.json', 'w') as f:
            json.dump(schema, f, indent=2, default=str)
        print("\nSchema saved to db_schema_dump.json")
        
    finally:
        await conn.close()

if __name__ == '__main__':
    asyncio.run(extract_schema())
