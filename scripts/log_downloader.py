#!/usr/bin/env python3

import asyncio
from mavsdk import System
import sys
import os


async def run():
    logs_dir = f"/home/{os.getenv('USER')}/Documents/logs"
    if not os.path.exists(logs_dir):
        os.makedirs(logs_dir)

    drone = System()
    print("Connecting to drone...")
    await drone.connect(system_address="tcp://:5760")

    print("Waiting for drone to connect...")
    async for state in drone.core.connection_state():
        if state.is_connected:
            print(f"-- Connected to drone!")
            break

    # print("Waiting for log entries...")

    # entries = await get_entries(drone)
    # for entry in entries:
    #     date_without_colon = entry.date.replace(":", "-")
    #     filename = f"/home/{os.getenv('USER')}/Documents/logs/log-{date_without_colon}.ulog"
    #     if not os.path.exists(filename):
    #         await download_log(drone, entry, filename)
    #     elif os.path.exists(filename) and ((abs(os.path.getsize(filename) - entry.size_bytes) > 300000)):
    #         print(f"Log {entry.id} from {entry.date} is not complete, redownloading...")
    #         print(f"Local filesize:  {os.path.getsize(filename)}")
    #         print(f"Remote filesize: {entry.size_bytes}")
    #         os.remove(filename)
    #         await download_log(drone, entry, filename)

    last_entries = await drone.log_files.get_entries()
    print(f"Number of entries: {len(last_entries)}")

    print("Waiting for new logs...")

    while True:
        await asyncio.sleep(5)
        entries = await drone.log_files.get_entries()
        print(f"Number of entries: {len(entries)}")
        
        if entries[-1] != last_entries[-1]:

            # get the latest entry
            latest_entry = entries[-1]
            print(f"New log {latest_entry.id} from {latest_entry.date} with size {latest_entry.size_bytes} bytes")
            date_without_colon = latest_entry.date.replace(":", "-")
            filename = f"/home/{os.getenv('USER')}/Documents/logs/log-{date_without_colon}.ulog"
            if not os.path.exists(filename):
                await download_log(drone, latest_entry, filename)

            last_entries = entries


async def download_log(drone, entry, filename):
    print(f"Downloading: log {entry.id} from {entry.date} to {filename}")
    previous_progress = -1
    async for progress in drone.log_files.download_log_file(entry, filename):
        new_progress = round(progress.progress*100)
        if new_progress != previous_progress:
            sys.stdout.write(f"\r{new_progress} %")
            sys.stdout.flush()
            previous_progress = new_progress
    print()


async def get_entries(drone):
    entries = await drone.log_files.get_entries()
    for entry in entries:
        print(f"Log {entry.id} from {entry.date}")
    return entries


if __name__ == "__main__":
    # Run the asyncio loop
    asyncio.run(run())
