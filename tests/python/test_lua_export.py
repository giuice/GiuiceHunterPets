import unittest

from scrapper.data_records import PetRecord, StableMasterRecord
from scrapper.lua_export import (
    export_pet_data,
    export_stable_master_data,
    lua_quote,
    validate_pet_records,
    validate_stable_master_records,
)


class LuaExportTest(unittest.TestCase):
    def test_lua_quote_escapes_strings(self):
        self.assertEqual(lua_quote('A "Wolf"'), '"A \\"Wolf\\""')

    def test_export_pet_data_preserves_pet_by_zones_shape(self):
        records = [
            PetRecord(
                zone_name="Isle of Dorn",
                zone_id=2248,
                name="Adolescent Darkwolf",
                maxlevel=80,
                minlevel=70,
                pet_class="Normal",
                family=(1, "Wolf"),
                display_id=70178,
                npc_id=226296,
                coords=((59.4, 34.6),),
            )
        ]

        lua = export_pet_data(records)

        self.assertIn("GHP.pet_by_zones = {", lua)
        self.assertIn('["zone_name"] = "Isle of Dorn"', lua)
        self.assertIn('["NpcId"] = 226296', lua)
        self.assertIn('["coords"] = { { 59.4, 34.6 } }', lua)

    def test_validate_pet_records_rejects_missing_coords(self):
        records = [
            PetRecord(
                zone_name="Bad Zone",
                zone_id=1,
                name="Bad Pet",
                maxlevel=1,
                minlevel=1,
                pet_class="Normal",
                family=(1, "Wolf"),
                display_id=0,
                npc_id=1,
                coords=(),
            )
        ]

        errors = validate_pet_records(records)

        self.assertEqual(errors, ["pet 1 Bad Pet has no coords"])

    def test_export_stable_master_data(self):
        records = [
            StableMasterRecord(
                npc_id=185561,
                name="Kaestrasz",
                zone_name="Valdrakken",
                zone_id=2112,
                coords=((62.0, 13.2),),
                faction="Neutral",
            )
        ]

        lua = export_stable_master_data(records)

        self.assertIn("GHP.stable_masters = {", lua)
        self.assertIn('["npcID"] = 185561', lua)
        self.assertIn('["faction"] = "Neutral"', lua)

    def test_validate_stable_master_records_rejects_bad_faction(self):
        records = [
            StableMasterRecord(
                npc_id=1,
                name="Bad Stable",
                zone_name="Bad Zone",
                zone_id=1,
                coords=((1.0, 2.0),),
                faction="Unknown",
            )
        ]

        errors = validate_stable_master_records(records)

        self.assertEqual(errors, ["stable master 1 Bad Stable has invalid faction Unknown"])


if __name__ == "__main__":
    unittest.main()
