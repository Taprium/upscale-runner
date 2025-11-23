from filelock import FileLock
from pocketbase import PocketBase
from pocketbase.client import FileUpload
import os
import urllib.request
import urllib.parse
import subprocess

pb = PocketBase(os.environ["PB_ADDR"])
pb_user = pb.collection("upscale_runners").auth_with_password(os.environ["PB_USER"],os.environ["PB_PASSWORD"])

PB_COLLECTION_IMAGE = "generated_images"

def upscale():
    to_upscale_record = pb.collection(PB_COLLECTION_IMAGE).get_first_list_item("selected=true && upscaled=false && runner=''",{
        "sort": "@random"
    })
    # if no record found, will throw exception, and exit
    
    # lock the runner
    pb.collection(PB_COLLECTION_IMAGE).update(to_upscale_record.id,body_params={
        "runner": pb_user.record.id
    })
    
    file_url = '{pb_host}/api/files/generated_images/{id}/{file}'.format(pb_host=pb.base_url,id=to_upscale_record.id,file=to_upscale_record.image)
    origin_file = 'to-upscale.png'
    upscaled_file_name = '{}.png'.format(to_upscale_record.id)
    urllib.request.urlretrieve(urllib.parse.urlparse(file_url).geturl(), origin_file)
    subprocess.run([
        "./realesrgan-ncnn-vulkan", 
        "-s","2",
        "-i", origin_file, 
        "-o", upscaled_file_name
    ], check=True)
    pb.collection(PB_COLLECTION_IMAGE).update(to_upscale_record.id,{
        'image':''
    })
    pb.collection(PB_COLLECTION_IMAGE).update(to_upscale_record.id,{
        'image':FileUpload(upscaled_file_name,open(upscaled_file_name,'rb')),
        'upscaled':True
    })
    os.remove(origin_file)
    os.remove(upscaled_file_name)

if __name__ == '__main__':
    lock = FileLock('/var/lock/run.lock')
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
    