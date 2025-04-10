import os
import shutil
import zipfile
import argparse

class DirectoryZipper:
    def __init__(self, source_dir, zip_file_path, temp_dir, exclude_dirs, exclude_files):
        self.source_dir = source_dir
        self.zip_file_path = zip_file_path
        self.temp_dir = temp_dir
        self.exclude_dirs = exclude_dirs
        self.exclude_files = exclude_files

    def copy_files(self, src, dst):
        for root, dirs, files in os.walk(src):
            # Exclude specified directories
            dirs[:] = [d for d in dirs if d not in self.exclude_dirs]
            for file in files:
                # Exclude specified files
                if file in self.exclude_files or any(file.endswith(ext) for ext in self.exclude_files):
                    continue
                src_file = os.path.join(root, file)
                dst_file = os.path.join(dst, os.path.relpath(src_file, src))
                os.makedirs(os.path.dirname(dst_file), exist_ok=True)
                shutil.copy2(src_file, dst_file)

    def create_zip(self):
        os.makedirs(self.temp_dir, exist_ok=True)
        self.copy_files(self.source_dir, self.temp_dir)

        with zipfile.ZipFile(self.zip_file_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(self.temp_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    zipf.write(file_path, os.path.relpath(file_path, self.temp_dir))

        # Clean up the temporary directory
        shutil.rmtree(self.temp_dir)

def main():
    parser = argparse.ArgumentParser(description="Zip a directory excluding specified files and directories.")
    parser.add_argument("source_dir", help="The source directory to zip.")
    parser.add_argument("zip_file_path", help="The path to the output zip file.")
    parser.add_argument("temp_dir", help="The temporary directory to use.")
    parser.add_argument("--exclude_dirs", nargs='*', default=[], help="Directories to exclude.")
    parser.add_argument("--exclude_files", nargs='*', default=[], help="Files to exclude.")

    args = parser.parse_args()

    zipper = DirectoryZipper(
        source_dir=args.source_dir,
        zip_file_path=args.zip_file_path,
        temp_dir=args.temp_dir,
        exclude_dirs=args.exclude_dirs,
        exclude_files=args.exclude_files
    )
    zipper.create_zip()

if __name__ == "__main__":
    main()
