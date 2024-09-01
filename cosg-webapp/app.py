from flask import Flask, render_template, redirect, url_for
import socket
import random
import os
import argparse
import mysql.connector
from datetime import datetime
import requests

app = Flask(__name__)

# Color codes dictionary to map color names to their hexadecimal values
color_codes = {
    "red": "#e74c3c",
    "green": "#16a085",
    "blue": "#2980b9",
    "blue2": "#2980b9",
    "pink": "#be2edd",
    "darkblue": "#130f40"
}

SUPPORTED_COLORS = ",".join(color_codes.keys())

# Get color from Environment variable
COLOR_FROM_ENV = os.environ.get('APP_COLOR')
# Generate a random color if not specified
COLOR = random.choice(["red", "green", "blue", "blue2", "darkblue", "pink"])

# MySQL Configuration from environment variables
DB_HOST = os.environ.get('DB_HOST')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
DB_NAME = os.environ.get('DB_NAME')

# URL to check reachability
CHECK_URL = os.environ.get('CHECK_URL')

# Check if all DB configuration parameters are provided
USE_DB = all([DB_HOST, DB_USER, DB_PASSWORD, DB_NAME])


def get_db_connection():
    """
    Create a connection to the MySQL database.

    This function establishes a connection to the specified MySQL database
    using the provided configuration parameters.

    Returns:
        connection (mysql.connector.connection.MySQLConnection): The MySQL database connection object.
    """
    connection = mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )
    return connection


def initialize_database():
    """
    Initialize the database if it does not exist.

    This function connects to MySQL without specifying a database and creates
    the specified database if it does not exist.
    """
    connection = mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD
    )
    cursor = connection.cursor()
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")
    cursor.close()
    connection.close()


def create_table():
    """
    Ensure the table exists.

    This function connects to the MySQL database and creates the `cosg_table` table
    if it does not exist. The table stores the timestamp and color of each request.
    """
    if USE_DB:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS cosg_table (
                id INT AUTO_INCREMENT PRIMARY KEY,
                timestamp DATETIME NOT NULL,
                color VARCHAR(50) NOT NULL
            )
        ''')
        connection.commit()
        cursor.close()
        connection.close()


def check_url_reachability(url):
    """
    Check if a URL is reachable.

    This function sends a GET request to the specified URL and checks if it returns a status code of 200.

    Args:
        url (str): The URL to check.

    Returns:
        bool: True if the URL is reachable (status code 200), False otherwise.
    """
    try:
        response = requests.get(url, timeout=5)
        return response.status_code == 200
    except requests.RequestException:
        return False


@app.route("/")
def main():
    """
    Main route of the Flask application.

    This function handles requests to the root URL ("/"). It logs the current request's
    timestamp and color to the MySQL database (if configured) and retrieves all records
    from the database to display them on the webpage. It also checks the reachability of a URL
    if specified via the environment variable.

    Returns:
        str: Rendered HTML template with the hostname, background color, records, and URL reachability status.
    """
    color = color_codes[COLOR]
    timestamp = datetime.now()

    if USE_DB:
        # Insert the current request's timestamp and color into the database
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute('INSERT INTO cosg_table (timestamp, color) VALUES (%s, %s)', (timestamp, color))
        connection.commit()

        # Retrieve all records from the database
        cursor.execute('SELECT timestamp, color FROM cosg_table')
        records = cursor.fetchall()
        cursor.close()
        connection.close()
    else:
        records = []

    url_reachable = None
    if CHECK_URL:
        # Check if the URL is reachable
        url_reachable = check_url_reachability(CHECK_URL)

    return render_template('hello.html', name=socket.gethostname(), color=color, records=records,
                           url_reachable=url_reachable, check_url=CHECK_URL)


@app.route("/flush", methods=["POST"])
def flush_db():
    """
    Flush the database by deleting all records from the `cosg_table` table.

    This function handles requests to the "/flush" URL and deletes all records
    from the `cosg_table` table in the MySQL database (if configured).

    Returns:
        redirect: Redirects to the main route ("/").
    """
    if USE_DB:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute('DELETE FROM cosg_table')
        connection.commit()
        cursor.close()
        connection.close()
    return redirect(url_for('main'))


if __name__ == "__main__":
    print(" This is a sample web application that displays a colored background. \n"
          " A color can be specified in two ways. \n"
          "\n"
          " 1. As a command line argument with --color as the argument. Accepts one of " + SUPPORTED_COLORS + " \n"
                                                                                                              " 2. As an Environment variable APP_COLOR. Accepts one of " + SUPPORTED_COLORS + " \n"
                                                                                                                                                                                               " 3. If none of the above then a random color is picked from the above list. \n"
                                                                                                                                                                                               " Note: Command line argument precedes over environment variable.\n"
                                                                                                                                                                                               "\n"
                                                                                                                                                                                               "")

    # Check for Command Line Parameters for color
    parser = argparse.ArgumentParser()
    parser.add_argument('--color', required=False)
    args = parser.parse_args()

    if args.color:
        print("Color from command line argument =" + args.color)
        COLOR = args.color
        if COLOR_FROM_ENV:
            print(
                "A color was set through environment variable -" + COLOR_FROM_ENV + ". However, color from command line argument takes precedence.")
    elif COLOR_FROM_ENV:
        print("No Command line argument. Color from environment variable =" + COLOR_FROM_ENV)
        COLOR = COLOR_FROM_ENV
    else:
        print("No command line argument or environment variable. Picking a Random Color =" + COLOR)

    # Check if input color is a supported one
    if COLOR not in color_codes:
        print("Color not supported. Received '" + COLOR + "' expected one of " + SUPPORTED_COLORS)
        exit(1)

    # Ensure the database and table exist if using DB
    if USE_DB:
        initialize_database()
        create_table()

    # Run Flask Application
    app.run(host="0.0.0.0", port=8080)