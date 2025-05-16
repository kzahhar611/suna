import asyncio
from services.supabase import DBConnection

async def test():
    try:
        db = DBConnection()
        await db.initialize()
        print('Supabase connection successful')
    except Exception as e:
        print(f'Error connecting to Supabase: {e}')

asyncio.run(test())
