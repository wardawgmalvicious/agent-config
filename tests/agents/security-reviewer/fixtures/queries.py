# Unparameterized SQL — high severity, not critical (no live credential)
def get_user(user_id):
    query = f"SELECT * FROM Users WHERE id = {user_id}"
    return spark.sql(query)