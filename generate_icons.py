from PIL import Image
import os

def generate_app_icons():
    # 源图标路径
    source_icon = "CristineNote/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
    output_dir = "CristineNote/Assets.xcassets/AppIcon.appiconset"
    
    # 确保源图标存在
    if not os.path.exists(source_icon):
        print(f"错误：找不到源图标文件 {source_icon}")
        return
        
    # 读取源图标
    with Image.open(source_icon) as img:
        # 确保源图标是1024x1024
        if img.size != (1024, 1024):
            print(f"警告：源图标尺寸不是1024x1024，当前尺寸为{img.size}")
            
        # 定义所需的图标尺寸
        icon_sizes = {
            "AppIcon-20.png": 20,
            "AppIcon-20@2x.png": 40,
            "AppIcon-20@3x.png": 60,
            "AppIcon-29.png": 29,
            "AppIcon-29@2x.png": 58,
            "AppIcon-29@3x.png": 87,
            "AppIcon-40.png": 40,
            "AppIcon-40@2x.png": 80,
            "AppIcon-40@3x.png": 120,
            "AppIcon-60@2x.png": 120,
            "AppIcon-60@3x.png": 180,
            "AppIcon-76.png": 76,
            "AppIcon-76@2x.png": 152,
            "AppIcon-83.5@2x.png": 167,
            "AppIcon-1024.png": 1024
        }
        
        # 生成各种尺寸的图标
        for filename, size in icon_sizes.items():
            output_path = os.path.join(output_dir, filename)
            # 使用LANCZOS重采样算法进行高质量缩放
            resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
            # 保存时使用最高质量
            resized_img.save(output_path, "PNG", quality=100, optimize=False)
            print(f"生成图标: {filename} ({size}x{size})")

if __name__ == "__main__":
    generate_app_icons() 