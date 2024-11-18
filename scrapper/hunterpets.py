from playwright.async_api import async_playwright
import re
import asyncio
import sqlite3
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from contextlib import contextmanager
import json
from datetime import datetime


@dataclass
class PetFamily:
    id: int
    name: str
    slug: str
    tameable_url: str
    is_processed: bool = False


@dataclass
class TameablePet:
    name: str
    min_level: Optional[int]
    max_level: Optional[int]
    pet_class: str
    zone_name: Optional[str]
    zone_id: Optional[int]
    alliance_react: int
    horde_react: int
    npc_id: str
    display_id: str
    coords: Optional[List[tuple]]
    family_id: int


class Database:
    def __init__(self, db_path: str = "wow_pets.db"):
        self.db_path = db_path
        self.init_db()

    @contextmanager
    def get_connection(self):
        conn = sqlite3.connect(self.db_path)
        try:
            yield conn
        finally:
            conn.close()

    def init_db(self):
        with self.get_connection() as conn:
            cursor = conn.cursor()

            # Create families table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS families (
                    id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL,
                    slug TEXT NOT NULL,
                    tameable_url TEXT NOT NULL,
                    is_processed BOOLEAN DEFAULT FALSE,
                    last_updated DATETIME,
                    exotic BOOLEAN DEFAULT FALSE,
                    diet TEXT,
                    pet_type TEXT
                )
            """)
            # create abilities table
            cursor.execute("""
                           CREATE TABLE IF NOT EXISTS abilities (
                spell_id INTEGER PRIMARY KEY UNIQUE NOT NULL,
                name TEXT NOT NULL
            )""")

            # Create family_abilities table
            cursor.execute("""
                           CREATE TABLE IF NOT EXISTS family_abilities (
                family_id INTEGER NOT NULL,
                ability_id INTEGER NOT NULL,
                FOREIGN KEY (family_id) REFERENCES families (id),
                FOREIGN KEY (ability_id) REFERENCES abilities (spell_id),
                PRIMARY KEY (family_id, ability_id)
            )""")

            # Create pets table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS pets (
                    npc_id TEXT PRIMARY KEY,
                    family_id INTEGER,
                    name TEXT NOT NULL,
                    min_level INTEGER,
                    max_level INTEGER,
                    pet_class TEXT,
                    zone_name TEXT,
                    zone_id INTEGER,
                    alliance_react INTEGER,
                    horde_react INTEGER,
                    display_id TEXT,
                    coords TEXT,
                    last_updated DATETIME,
                    mapID INTEGER,
                    FOREIGN KEY (family_id) REFERENCES families (id)
                )
            """)

            conn.commit()

    def save_family(self, family: PetFamily):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT OR REPLACE INTO families (id, name, slug, tameable_url, is_processed, last_updated)
                VALUES (?, ?, ?, ?, ?, ?)
            """,
                (
                    family.id,
                    family.name,
                    family.slug,
                    family.tameable_url,
                    family.is_processed,
                    datetime.now().isoformat(),
                ),
            )
            conn.commit()

    def update_family(self, family_id: int, updates: dict):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                UPDATE families
                SET exotic = ?,
                    diet = ?,
                    pet_type = ?
                WHERE id = ?
            """,
                (
                    updates.get("exotic"),
                    updates.get("diet"),
                    updates.get("pet_type"),
                    family_id,
                ),
            )
            conn.commit()

    def save_ability(self, spell_id: int, name: str):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT OR IGNORE INTO abilities (spell_id, name)
                VALUES (?, ?)
            """,
                (spell_id, name),
            )
            conn.commit()

    def save_family_ability(self, family_id: int, ability_spell_id: int):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            # Get ability id
            cursor.execute(
                "SELECT spell_id FROM abilities WHERE spell_id = ?", (ability_spell_id,)
            )
            ability_row = cursor.fetchone()
            if ability_row:
                ability_id = ability_spell_id
                cursor.execute(
                    """
                    INSERT INTO family_abilities (family_id, ability_id)
                    VALUES (?, ?)
                """,
                    (family_id, ability_id),
                )
                conn.commit()

    def save_pet(self, pet: TameablePet):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT OR REPLACE INTO pets (
                    npc_id, family_id, name, min_level, max_level, pet_class,
                    zone_name, zone_id, alliance_react, horde_react,
                    display_id, coords, last_updated
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
                (
                    pet.npc_id,
                    pet.family_id,
                    pet.name,
                    pet.min_level,
                    pet.max_level,
                    pet.pet_class,
                    pet.zone_name,
                    pet.zone_id,
                    pet.alliance_react,
                    pet.horde_react,
                    pet.display_id,
                    json.dumps(pet.coords),
                    datetime.now().isoformat(),
                ),
            )
            conn.commit()

    def get_unprocessed_families(self) -> List[PetFamily]:
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT id, name, slug, tameable_url, is_processed
                FROM families
                WHERE is_processed = FALSE
            """)
            return [PetFamily(*row) for row in cursor.fetchall()]

    def mark_family_as_processed(self, family_id: int):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                UPDATE families
                SET is_processed = TRUE,
                    last_updated = ?
                WHERE id = ?
            """,
                (datetime.now().isoformat(), family_id),
            )
            conn.commit()

    def get_processed_pets_for_family(self, family_id: int) -> List[str]:
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                SELECT npc_id
                FROM pets
                WHERE family_id = ?
            """,
                (family_id,),
            )
            return [row[0] for row in cursor.fetchall()]
    
    def escape_lua_string(self, s: str) -> str:
        return s.replace('"', '\\"')

    def export_pets_by_zone_to_lua(self, output_file: str = "hunter_pets.lua"):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT p.*, f.name as family_name, f.id as family_id, f.slug as slug
                FROM pets p
                JOIN families f ON p.family_id = f.id
            """)

            pets_data = cursor.fetchall()
            column_names = [description[0] for description in cursor.description]

            with open(output_file, "w") as f:
                f.write("local HUNTER_PETS = {\n")

                for pet_data in pets_data:
                    pet_dict = dict(zip(column_names, pet_data))
                    coords = json.loads(pet_dict["coords"])

                    f.write("    {\n")
                    f.write(
                        f'        ["zone_name"] = "{pet_dict["zone_name"] or ""}",\n'
                    )
                    f.write(f'        ["zoneID"] = {pet_dict["mapID"] or 0},\n')
                    f.write(f'        ["name"] = "{self.escape_lua_string(pet_dict["name"])}",\n')
                    f.write(f'        ["maxlevel"] = {pet_dict["max_level"] or 0},\n')
                    f.write(f'        ["minlevel"] = {pet_dict["min_level"] or 0},\n')
                    f.write(f'        ["class"] = "{pet_dict["pet_class"]}",\n')
                    f.write(
                        f'        ["family"] = {{ {pet_dict["family_id"]}, "{pet_dict["family_name"]}"}},\n'
                    )
                    f.write(f'        ["displayId"] = {pet_dict["display_id"]},\n')
                    f.write(f'        ["NpcId"] = {pet_dict["npc_id"]},\n')

                    # Format coordinates
                    coord_str = ", ".join([f"{{ {x}, {y} }}" for x, y in coords])
                    f.write(f'        ["coords"] = {{ {coord_str} }},\n')

                    f.write("    },\n")

                f.write("}\n\nreturn HUNTER_PETS")

    def export_families_to_lua(self, output_file: str = "families_data.lua"):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT f.id, f.exotic, f.diet, f.pet_type, a.name as ability, a.spell_id
                FROM families f
                JOIN family_abilities fa ON fa.family_id = f.id
                JOIN abilities a ON fa.ability_id = a.spell_id
            """)
            rows = cursor.fetchall()

            # Group abilities by family
            family_data = {}
            for row in rows:
                family_id = row[0]
                exotic = row[1]
                diet = row[2]
                pet_type = row[3]
                ability_name = row[4]
                ability_spell_id = row[5]

                if family_id not in family_data:
                    family_data[family_id] = {
                        "exotic": exotic,
                        "diet": diet,
                        "pet_type": pet_type,
                        "abilities": [],
                    }
                family_data[family_id]["abilities"].append(
                    {"name": ability_name, "spell_id": ability_spell_id}
                )

        # Write to Lua file
        with open(output_file, "w") as f:
            f.write("local FAMILY_DATA = {\n")
            for family_id, data in family_data.items():
                f.write(f"    [{family_id}] = {{\n")
                f.write(f"        exotic = {str(data['exotic']).lower()},\n")
                f.write(f"        diet = \"{data['diet']}\",\n")
                f.write(f"        pet_type = \"{data['pet_type']}\",\n")
                f.write("        abilities = {\n")
                for ability in data["abilities"]:
                    f.write(
                        f"            {{ name = \"{ability['name']}\", spell_id = {ability['spell_id']} }},\n"
                    )
                f.write("        },\n")
                f.write("    },\n")
            f.write("}\n\nreturn FAMILY_DATA")


class WowPetScraper:
    BASE_URL = "https://www.wowhead.com/hunter-pets"

    def __init__(self, db_path: str = "wow_pets.db"):
        self.db = Database(db_path)
        self.browser = None
        self.page = None

    async def init_browser(self):
        p = await async_playwright().start()
        self.browser = await p.chromium.launch(headless=True)
        self.page = await self.browser.new_page()

    async def close_browser(self):
        if self.browser:
            await self.browser.close()

    async def fetch_pet_families(self) -> List[PetFamily]:
        if not self.page:
            await self.init_browser()

        await self.page.goto(self.BASE_URL)
        await self.page.wait_for_selector("a.listview-cleartext", timeout=10000)

        elements = await self.page.query_selector_all("a.listview-cleartext")
        families = []

        for element in elements:
            href = await element.get_attribute("href")
            if "/pet=" in href:
                family_id = int(re.search(r"/pet=(\d+)/", href).group(1))
                family_name = await element.inner_text()
                family_slug = href.split("/")[-1]

                families.append(
                    PetFamily(
                        id=family_id,
                        name=family_name.strip(),
                        slug=family_slug,
                        tameable_url=f"{href}#tameable",
                    )
                )

        return families

    async def get_reaction_value(self, reaction_span) -> int:
        if not reaction_span:
            return 0
        class_name = await reaction_span.get_attribute("class")
        if "q10" in class_name:
            return -1
        elif "q2" in class_name:
            return 1
        return 0

    async def extract_coords_from_pins(self, pins) -> List[tuple]:
        coords = []
        for pin in pins:
            style = await pin.get_attribute("style")
            left_match = re.search(r"left:\s*([\d.]+)%", style)
            top_match = re.search(r"top:\s*([\d.]+)%", style)

            if left_match and top_match:
                coords.append((float(left_match.group(1)), float(top_match.group(1))))
        return coords

    async def has_next_page(self) -> bool:
        next_link = await self.page.query_selector(
            'a[data-active="yes"]:has-text("Next")'
        )
        return bool(next_link)

    async def fetch_tameable_pets(
        self, row, family: PetFamily, page_offset: int = 0
    ) -> List[TameablePet]:
        url = f"{family.tameable_url}"
        if page_offset > 0:
            url += f";{page_offset}"

        await self.page.goto(url, timeout=120000)  # 2 minutes timeout
        await self.page.wait_for_selector(".listview-row", timeout=120000)

        rows = await self.page.query_selector_all(".listview-row")
        pets = []

        for row in rows:
            # Extract zone info
            zone_link = await row.query_selector("td:nth-child(3) a")
            zone_name = zone_href = zone_id = None
            if zone_link:
                zone_name = await zone_link.inner_text()
                zone_href = await zone_link.get_attribute("href")
                zone_id = int(re.search(r"/zone=(\d+)/", zone_href).group(1))
            else:
                continue

            # Extract basic info
            name_link = await row.query_selector("a.listview-cleartext")
            name = await name_link.inner_text()

            # Extract levels and class
            level_cell = await row.query_selector("td:nth-child(2)")
            level_text = await level_cell.inner_text()
            levels = re.findall(r"\d+", level_text)
            # levels = re.findall(r'\d+', level_text)

            if not levels:
                min_level = max_level = None
            elif len(levels) == 1:
                min_level = max_level = int(levels[0])
            else:
                min_level, max_level = int(levels[0]), int(levels[-1])

            pet_class = (
                "Rare"
                if "Rare" in level_text
                else "Elite"
                if "Elite" in level_text
                else "Normal"
            )

            # Extract zone info
            zone_link = await row.query_selector("td:nth-child(3) a")
            zone_name = zone_href = zone_id = None
            if zone_link:
                zone_name = await zone_link.inner_text()
                zone_href = await zone_link.get_attribute("href")
                zone_id = int(re.search(r"/zone=(\d+)/", zone_href).group(1))

            # Extract reaction info
            alliance_span = await row.query_selector("td:nth-child(4) span:first-child")
            horde_span = await row.query_selector("td:nth-child(4) span:last-child")
            alliance_react = await self.get_reaction_value(alliance_span)
            horde_react = await self.get_reaction_value(horde_span)

            # Get NPC link for detailed info
            npc_href = await name_link.get_attribute("href")

            # Navigate to NPC page
            npc_page = await self.browser.new_page()
            await npc_page.goto(npc_href)

            # Extract display ID and NPC ID
            model_button = await npc_page.query_selector("#open-links-button")
            # onclick_attr = await model_button.get_attribute('onclick')
            display_id = await model_button.get_attribute("data-display-id")
            npc_id = None
            npc_id_match = re.search(r"npc=(\d+)", npc_href)
            if npc_id_match:
                npc_id = npc_id_match.group(1)
            else:
                npc_id = None

            # Extract coordinates
            pins = await npc_page.query_selector_all(".pin")
            coords = await self.extract_coords_from_pins(pins)
            print("coords:", coords)

            await npc_page.close()

            pets.append(
                TameablePet(
                    name=name,
                    min_level=min_level,
                    max_level=max_level,
                    pet_class=pet_class,
                    zone_name=zone_name,
                    zone_id=zone_id,
                    alliance_react=alliance_react,
                    horde_react=horde_react,
                    npc_id=npc_id,
                    display_id=display_id,
                    coords=coords,
                    family_id=family.id,
                )
            )
            # print("pets:", pets)

        return pets

    async def fetch_process_single_pet(
        self, row, processed_pets, family_id: int
    ) -> TameablePet:
        # Extract basic info
        name_link = await row.query_selector("a.listview-cleartext")
        name = await name_link.inner_text()

        # Get NPC link for detailed info
        npc_href = await name_link.get_attribute("href")
        npc_id = re.search(r"/npc=(\d+)/", npc_href).group(1)

        # Skip if already processed
        if npc_id in processed_pets:
            print(f"Skipping already processed pet: {name}")
            return

        # Extract zone info
        zone_link = await row.query_selector("td:nth-child(3) a")
        zone_name = zone_href = zone_id = None
        if zone_link:
            zone_name = await zone_link.inner_text()
            zone_href = await zone_link.get_attribute("href")
            zone_id = int(re.search(r"/zone=(\d+)/", zone_href).group(1))
        else:
            return

        # Extract levels and class
        level_cell = await row.query_selector("td:nth-child(2)")
        level_text = await level_cell.inner_text()
        levels = re.findall(r"\d+", level_text)
        # levels = re.findall(r'\d+', level_text)

        if not levels:
            min_level = max_level = None
        elif len(levels) == 1:
            min_level = max_level = int(levels[0])
        else:
            min_level, max_level = int(levels[0]), int(levels[-1])

        pet_class = (
            "Rare"
            if "Rare" in level_text
            else "Elite"
            if "Elite" in level_text
            else "Normal"
        )

        # Extract zone info
        zone_link = await row.query_selector("td:nth-child(3) a")
        zone_name = zone_href = zone_id = None
        if zone_link:
            zone_name = await zone_link.inner_text()
            zone_href = await zone_link.get_attribute("href")
            zone_id = int(re.search(r"/zone=(\d+)/", zone_href).group(1))

        # Extract reaction info
        alliance_span = await row.query_selector("td:nth-child(4) span:first-child")
        horde_span = await row.query_selector("td:nth-child(4) span:last-child")
        alliance_react = await self.get_reaction_value(alliance_span)
        horde_react = await self.get_reaction_value(horde_span)

        # Navigate to NPC page
        npc_page = await self.browser.new_page()
        await npc_page.goto(npc_href)

        # Extract display ID and NPC ID
        model_button = await npc_page.query_selector("#open-links-button")
        # onclick_attr = await model_button.get_attribute('onclick')
        display_id = await model_button.get_attribute("data-display-id")

        # Extract coordinates
        pins = await npc_page.query_selector_all(".pin")
        coords = await self.extract_coords_from_pins(pins)

        await npc_page.close()

        # Create and save pet
        pet = TameablePet(
            name=name,
            min_level=min_level,
            max_level=max_level,
            pet_class=pet_class,
            zone_name=zone_name,
            zone_id=zone_id,
            alliance_react=alliance_react,
            horde_react=horde_react,
            npc_id=npc_id,
            display_id=display_id,
            coords=coords,
            family_id=family_id,
        )

        self.db.save_pet(pet)
        processed_pets.add(npc_id)
        print(f"Successfully saved pet: {name}")

    async def process_all_families(self):
        try:
            # First, fetch and save all families if not already in DB
            # families = await self.fetch_pet_families()
            # for family in families:
            #     self.db.save_family(family)

            # Process unprocessed families
            unprocessed_families = self.db.get_unprocessed_families()
            for family in unprocessed_families:
                print(f"\nProcessing {family.name}...")

                # Get already processed pets for this family
                processed_pets = set(self.db.get_processed_pets_for_family(family.id))
                page_offset = 0

                while True:
                    try:
                        await self.init_browser()
                        url = f"{family.tameable_url}"
                        if page_offset > 0:
                            url += f";{page_offset}"
                        print(f"Fetching page {url}...")
                        await self.page.goto(url, timeout=120000)

                        await self.page.wait_for_selector(
                            ".listview-row", timeout=120000
                        )

                        rows = await self.page.query_selector_all(".listview-row")
                        print(rows)
                        try:
                            for row in rows:
                                await self.fetch_process_single_pet(
                                    row, processed_pets, family.id
                                )

                        except Exception as e:
                            print(f"Error processing pet: {str(e)}")
                            continue

                        if not await self.has_next_page():
                            break

                        page_offset += 100

                    except Exception as e:
                        print(
                            f"Error processing family {family.name} at offset {page_offset}: {str(e)}"
                        )
                        await asyncio.sleep(30)
                        continue
                    finally:
                        await self.close_browser()

                # Mark family as processed
                self.db.mark_family_as_processed(family.id)

        finally:
            await self.close_browser()

    async def update_family_details(self):
        if not self.page:
            await self.init_browser()

        await self.page.goto(self.BASE_URL)
        await self.page.wait_for_selector("table.listview-mode-default")

        # Get all the table rows
        rows = await self.page.query_selector_all(
            "table.listview-mode-default tbody tr.listview-row"
        )

        for row in rows:
            # Get family link
            family_link = await row.query_selector("a.listview-cleartext")
            href = await family_link.get_attribute("href")
            name = await family_link.inner_text()

            family_id_match = re.search(r"/pet=(\d+)", href)
            if family_id_match:
                family_id = int(family_id_match.group(1))
            else:
                continue

            # Get exotic
            exotic = False
            exotic_link = await row.query_selector("div.listview-name-info a")
            if exotic_link:
                exotic_href = await exotic_link.get_attribute("href")
                if "spell=53270" in exotic_href:
                    exotic = True

            # Get abilities
            abilities = []
            ability_divs = await row.query_selector_all("td:nth-child(4) div.iconsmall")
            for ability_div in ability_divs:
                ability_link = await ability_div.query_selector("a")
                ability_href = await ability_link.get_attribute("href")
                ability_name = ability_href.split("/")[-1]
                ability_id_match = re.search(r"/spell=(\d+)", ability_href)
                if ability_id_match:
                    ability_id = int(ability_id_match.group(1))
                    abilities.append((ability_id, ability_name))

            # Get diet
            diet_td = await row.query_selector("td:nth-child(5)")
            diet = await diet_td.inner_text()

            # Get type
            type_td = await row.query_selector("td:nth-child(6)")
            type_link = await type_td.query_selector("a")
            pet_type = await type_link.inner_text()

            # Update family in database
            self.db.update_family(
                family_id,
                {"exotic": exotic, "diet": diet.strip(), "pet_type": pet_type.strip()},
            )

            # Save abilities and link to family
            for ability_id, ability_name in abilities:
                self.db.save_ability(ability_id, ability_name)
                self.db.save_family_ability(family_id, ability_id)

        self.close_browser()


async def main():
    scraper = WowPetScraper()
    await scraper.process_all_families()

    # Export to Lua format
    # scraper.db.export_to_lua()


async def main2():
    scraper = WowPetScraper()
    await scraper.update_family_details()


async def main3():
    db = Database()
    db.export_families_to_lua()


if __name__ == "__main__":
    db = Database()
    db.export_pets_by_zone_to_lua()
    # asyncio.run(main2())
    #asyncio.run(main3())
