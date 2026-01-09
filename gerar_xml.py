import os
import hashlib
import xml.etree.ElementTree as ET
from xml.dom import minidom

def calculate_hash(filepath):
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def generate_xml():
    root = ET.Element("updates")
    ET.SubElement(root, "version").text = "1.0.0"
    ET.SubElement(root, "launcher_version").text = "1.0"
    files_node = ET.SubElement(root, "files")

    # Pastas que você quer que o Launcher verifique
    dirs_to_scan = ['data', 'modules', 'init.lua'] 
    
    for item in os.listdir('.'):
        if item in dirs_to_scan or item.endswith('.exe') or item.endswith('.dll'):
            if os.path.isfile(item):
                f_node = ET.SubElement(files_node, "file")
                f_node.set("name", item)
                f_node.set("hash", calculate_hash(item))
            else:
                for root_dir, _, files in os.walk(item):
                    for file in files:
                        filepath = os.path.join(root_dir, file)
                        relative_path = filepath.replace("\\", "/")
                        f_node = ET.SubElement(files_node, "file")
                        f_node.set("name", relative_path)
                        f_node.set("hash", calculate_hash(filepath))

    # Formatar o XML para ficar bonito
    xml_str = minidom.parseString(ET.tostring(root)).toprettyxml(indent="   ")
    with open("updates.xml", "w", encoding="utf-8") as f:
        f.write(xml_str)
    print("Sucesso! updates.xml gerado.")

if __name__ == "__main__":
    generate_xml()