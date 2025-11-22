from filelock import FileLock
from pocketbase import PocketBase
from pocketbase.client import FileUpload
import os

pb = PocketBase(os.environ["PB_ADDR"])
pb_user = pb.collection("upscale_runners").auth_with_password(os.environ["PB_USER"],os.environ["PB_PASSWORD"])

def upscale():
    to_upscale_record = pb.collection("generated_images").get_first_list_item("selected=true && upscaled=false && runner=''",{
        ""
    })
    pass

if __name__ == '__name__':
    lock = FileLock('run.lock')
    try:
        lock.acquire(blocking=True)
    except:
        print("Another upscale process is running.")
        exit()
    
    try:
        upscale()
    except:
        exit()
    
    lock.release()
    