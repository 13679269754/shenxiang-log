import os
import sys

def check():
    print(f"Python Executable: {sys.executable}")
    print(f"Current Dir: {os.getcwd()}")
    try:
        import fastapi
        print("FastAPI: OK")
    except ImportError:
        print("FastAPI: Missing")
        
    try:
        import uvicorn
        print("Uvicorn: OK")
    except ImportError:
        print("Uvicorn: Missing")

if __name__ == "__main__":
    check()
