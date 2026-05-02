import unittest

from scrapper.wowhead_source import (
    extract_js_assignment,
    extract_mapper_data,
    extract_listview_data,
)


class WowheadSourceTest(unittest.TestCase):
    def test_extracts_listview_data_assignment(self):
        html = """
        <script>
        new Listview({
            template: 'pet',
            id: 'pets',
            data: [{"id":1,"name":"Wolf"},{"id":2,"name":"Cat"}]
        });
        </script>
        """

        rows = extract_listview_data(html, "pets")

        self.assertEqual(rows, [{"id": 1, "name": "Wolf"}, {"id": 2, "name": "Cat"}])

    def test_extracts_named_assignment(self):
        html = """
        <script>
        var g_mapperData = {"12":[{"uiMapId":37,"uiMapName":"Elwynn Forest","coords":[[72.4,65.0]]}]};
        </script>
        """

        data = extract_js_assignment(html, "g_mapperData")

        self.assertEqual(data["12"][0]["uiMapId"], 37)
        self.assertEqual(data["12"][0]["coords"], [[72.4, 65.0]])

    def test_extracts_listview_data_with_unquoted_js_keys(self):
        html = """
        <script>
        new Listview({
            template: 'npc',
            id: 'tameable',
            data: [{"id":32517,"name":"Loque'nahak",skin: ""}]
        });
        </script>
        """

        rows = extract_listview_data(html, "tameable")

        self.assertEqual(rows, [{"id": 32517, "name": "Loque'nahak", "skin": ""}])

    def test_extracts_mapper_data(self):
        html = """
        <script>
        g_mapperData={"13644":[{"uiMapId":2022,"uiMapName":"The Waking Shores","coords":[[48.2,83.4],[48.4,83.6]]}]};
        </script>
        """

        data = extract_mapper_data(html)

        self.assertEqual(data["13644"][0]["uiMapId"], 2022)
        self.assertEqual(len(data["13644"][0]["coords"]), 2)

    def test_missing_assignment_returns_none(self):
        self.assertIsNone(extract_js_assignment("<html></html>", "g_mapperData"))


if __name__ == "__main__":
    unittest.main()
