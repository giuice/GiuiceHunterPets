import unittest

from scrapper.data_records import (
    PetFamilySourceRow,
    TameablePetSourceRow,
    build_pet_record,
    build_stable_master_record,
    classification_label,
    faction_label,
)


class DataRecordsTest(unittest.TestCase):
    def test_classification_label(self):
        self.assertEqual(classification_label(0), "Normal")
        self.assertEqual(classification_label(1), "Elite")
        self.assertEqual(classification_label(4), "Rare")
        self.assertEqual(classification_label(2), "Rare Elite")
        self.assertEqual(classification_label(None), "Normal")

    def test_faction_label(self):
        self.assertEqual(faction_label([1, -1]), "Alliance")
        self.assertEqual(faction_label([-1, 1]), "Horde")
        self.assertEqual(faction_label([1, 1]), "Neutral")
        self.assertEqual(faction_label([0, 0]), "Neutral")

    def test_source_tameable_rows_normalizes_null_react_values(self):
        from scrapper.data_records import source_tameable_rows

        rows = source_tameable_rows(
            [
                {
                    "id": 88710,
                    "name": "Lost Netherwolf",
                    "family": 46,
                    "classification": 0,
                    "location": [672],
                    "react": [-1, None],
                    "minlevel": 10,
                    "maxlevel": 10,
                }
            ]
        )

        self.assertEqual(rows[0].react, [-1, 0])

    def test_source_tameable_rows_allows_missing_family(self):
        from scrapper.data_records import source_tameable_rows

        rows = source_tameable_rows(
            [
                {
                    "id": 122963,
                    "name": "Rezan",
                    "classification": 1,
                    "location": [9028],
                    "react": [-1, -1],
                }
            ]
        )

        self.assertEqual(rows[0].family, 0)

    def test_build_pet_record_uses_mapper_ui_map_id_and_coords(self):
        family = PetFamilySourceRow(id=1, name="Wolf")
        tameable = TameablePetSourceRow(
            id=226296,
            name="Adolescent Darkwolf",
            family=1,
            classification=0,
            location=[2248],
            react=[-1, -1],
            minlevel=70,
            maxlevel=80,
        )
        mapper_data = {
            "2248": [
                {
                    "uiMapId": 2248,
                    "uiMapName": "Isle of Dorn",
                    "coords": [[59.4, 34.6], [59.6, 34.4]],
                }
            ]
        }

        record = build_pet_record(family, tameable, mapper_data)

        self.assertEqual(record.zone_name, "Isle of Dorn")
        self.assertEqual(record.zone_id, 2248)
        self.assertEqual(record.name, "Adolescent Darkwolf")
        self.assertEqual(record.npc_id, 226296)
        self.assertEqual(record.family, (1, "Wolf"))
        self.assertEqual(record.pet_class, "Normal")
        self.assertEqual(record.coords, ((59.4, 34.6), (59.6, 34.4)))

    def test_build_pet_record_accepts_nested_mapper_entries(self):
        family = PetFamilySourceRow(id=46, name="Spirit Beast")
        tameable = TameablePetSourceRow(
            id=60410,
            name="Elegon",
            family=46,
            classification=0,
            location=[6125],
            react=[0, 0],
            minlevel=35,
            maxlevel=35,
        )
        mapper_data = {"6125": {"3": {"count": 2, "coords": [[20.6, 51.5], [20.7, 51.1]]}}}

        record = build_pet_record(family, tameable, mapper_data)

        self.assertEqual(record.zone_id, 6125)
        self.assertEqual(record.coords, ((20.6, 51.5), (20.7, 51.1)))

    def test_build_stable_master_record(self):
        row = {
            "id": 185561,
            "name": "Kaestrasz",
            "tag": "Stable Master",
            "react": [1, 1],
            "location": [13862],
        }
        mapper_data = {
            "13862": [
                {
                    "uiMapId": 2112,
                    "uiMapName": "Valdrakken",
                    "coords": [[62.0, 13.2]],
                }
            ]
        }

        record = build_stable_master_record(row, mapper_data)

        self.assertEqual(record.npc_id, 185561)
        self.assertEqual(record.name, "Kaestrasz")
        self.assertEqual(record.zone_id, 2112)
        self.assertEqual(record.zone_name, "Valdrakken")
        self.assertEqual(record.coords, ((62.0, 13.2),))
        self.assertEqual(record.faction, "Neutral")


if __name__ == "__main__":
    unittest.main()
