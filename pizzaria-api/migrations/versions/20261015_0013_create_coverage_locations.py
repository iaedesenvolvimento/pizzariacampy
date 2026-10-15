"""create initial delivery coverage location catalog

Revision ID: 20261015_0013
Revises: 20261014_0012
"""
from collections.abc import Sequence
from uuid import uuid4

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "20261015_0013"
down_revision: str | None = "20261014_0012"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


BARUERI = "Aldeia da Serra|Altos|Califórnia|Engenho Novo|Cruz Preta|Boa Vista|Alphaville|Jubran|Tamboré|Mutinga|Aldeia|Centro|Fazenda Militar|Belval|Silveira|Votupoca".split("|")
OSASCO = "Adalgisa|Aliança|Ayrosa|Bandeiras|Baronesa|Bela Vista|Bonança|Bonfim|Bussocaba|Castelo Branco|Centro|Cidade das Flores|Cidade de Deus|Cipava|City Bussocaba|Helena Maria|I.A.P.I.|Industrial Altino|Industrial Anhanguera|Industrial Autonomistas|Industrial Centro|Industrial Mazzei|Industrial Remédios|Jaguaribe|Jardim Conceição|Jardim D’Abril|Jardim das Flores|Jardim Elvira|Jardim Novo Osasco|Jardim Roberto|Km 18|Metalúrgicos|Munhoz Júnior|Mutinga|Padroeira|Paiva Ramos|Parque Continental|Pestana|Piratininga|Platina|Portal D’Oeste|Presidente Altino|Quitaúna|Raposo Tavares|Remédios|Rochdale|Santa Fé|Santa Maria|Santo Antônio|São Pedro|Setor Militar|Três Montanhas|Umuarama|Veloso|Vila Campesina|Vila Menck|Vila Militar|Vila Osasco|Vila Yara|Vila Yolanda".split("|")
CARAPICUIBA = "Águas da Fazendinha|Aldeia da Fazendinha|Alto da Vila Menck|Alto de Santa Lúcia|Área Rural de Carapicuíba|Bela Vista|Centro|Chácara Adriana Aparecida|Chácara das Candeias|Chácara das Flores|Chácara das Paineiras|Chácara de La Rocca|Chácara do Refúgio|Chácara dos Junqueiras|Chácara dos Lagos|Chácara Granja Velha|Chácara Moinho Velho|Chácara Noel Antônio|Chácara Quiriri|Chácara Santa Lúcia|Chácara Santa Lúcia dos Ypes|Chácara São João|Chácara Vale do Rio Cotia|Cidade Ariston Estela Azevedo|Conjunto Habitacional 120 Casas|Conjunto Habitacional Presidente Castelo Branco|Golf Gardens|Golf Park|Granja Santa Maria|Granja Viana|Jardim Alfredo Soncini|Jardim Alice|Jardim Ampermag|Jardim Ana Estela|Jardim Ana Maria|Jardim Ângela Maria|Jardim Angélica|Jardim Boa Vista|Jardim Bom Pastor|Jardim Bom Sucesso|Jardim Carapicuíba|Jardim Cecília Cristina|Jardim Cibele|Jardim Colonial|Jardim D’Ângelo|Jardim das Belezas|Jardim das Palmeiras|Jardim das Pedras|Jardim dos Manacás|Jardim Edi|Jardim Elzinha|Jardim Ercy|Jardim Felipe|Jardim Guiomar|Jardim Helena|Jardim Hermínia|Jardim Leonor|Jardim Leopoldina|Jardim Lice|Jardim Maria Beatriz|Jardim Maria Helena|Jardim Maria Rita|Jardim Marilu|Jardim Mesquita|Jardim Novo Horizonte|Jardim Paulista|Jardim Pignatary|Jardim Planalto|Jardim Popular|Jardim Primavera|Jardim Primeiro de Maio|Jardim Rosa Maria|Jardim Roseli|Jardim Sandra Regina|Jardim Santa Brígida|Jardim Santa Rita|Jardim Santa Tereza|Jardim Santo Estêvão|Jardim São Daniel|Jardim São José|Jardim São Pedro|Jardim Ster-Za|Jardim Tonato|Jardim Tucunduva|Jardim Yaya|Nova Fazendinha|Palos Verdes|Parque Flórida|Parque Ideal|Parque Jandaia|Parque José Alex André|Parque Primavera|Parque Roseira|Parque Sampaio Viana|Parque Santa Teresa|Pontal da Fazendinha|Pousada dos Bandeirantes|Recantinho|Recanto Campy|Recanto Impla|Recanto Verde|Residencial Euroville|Sítio Guarehy|Sítio Pereira Leite|Terras do Madeira|Vila América|Vila Anunciata|Vila Appia Antica|Vila Artem|Vila Balog|Vila Bela|Vila Bolivar|Vila Caldas|Vila Capriotti|Vila Clara|Vila Conquista|Vila Creti|Vila Cristina|Vila da Oportunidade|Vila Dirce|Vila Diva|Vila dos Andrades|Vila Ema|Vila Ester|Vila Freitas|Vila Gobbi|Vila Guarani|Vila Gustavo Correia|Vila Helemar|Vila Iza|Vila Janete|Vila Jussara|Vila Leopoldo|Vila Lisboa|Vila Lourdes|Vila Marcondes|Vila Margarida|Vila Maria Helena|Vila Martins|Vila Menk|Vila Mercês|Vila Mor|Vila Municipal|Vila Nossa Senhora Aparecida|Vila Olivina|Vila Quintino|Vila Rosa|Vila Santa Lúcia|Vila Santa Terezinha|Vila Santo Antônio|Vila São Jorge|Vila São José|Vila Silva Ribeiro|Vila Silviânia|Vila Sul Americana|Vila Tambory|Vila Teresa|Vila Terezinha|Vila Três Irmãos|Vila Veloso|Vilarejo".split("|")


def _rows(city: str, neighborhoods: list[str], source: str) -> list[dict[str, object]]:
    return [
        {
            "id": uuid4(),
            "city": city,
            "neighborhood": neighborhood,
            "aliases": None,
            "source": source,
            "is_active": False,
        }
        for neighborhood in neighborhoods
    ]


def upgrade() -> None:
    op.create_table(
        "coverage_locations",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("city", sa.String(120), nullable=False),
        sa.Column("neighborhood", sa.String(120), nullable=False),
        sa.Column("aliases", sa.Text(), nullable=True),
        sa.Column("source", sa.String(80), server_default=sa.text("'initial_mapping'"), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("city", "neighborhood", name="uq_coverage_locations_city_neighborhood"),
    )
    op.create_index("ix_coverage_locations_city", "coverage_locations", ["city"])
    op.create_index("ix_coverage_locations_neighborhood", "coverage_locations", ["neighborhood"])
    locations = (
        _rows("Barueri", BARUERI, "official_municipal")
        + _rows("Osasco", OSASCO, "official_municipal")
        + _rows("Carapicuíba", CARAPICUIBA, "postal_candidate")
    )
    op.bulk_insert(sa.table("coverage_locations", *[
        sa.Column("id", postgresql.UUID(as_uuid=True)),
        sa.Column("city", sa.String(120)),
        sa.Column("neighborhood", sa.String(120)),
        sa.Column("aliases", sa.Text()),
        sa.Column("source", sa.String(80)),
        sa.Column("is_active", sa.Boolean()),
    ]), locations)


def downgrade() -> None:
    op.drop_index("ix_coverage_locations_neighborhood", table_name="coverage_locations")
    op.drop_index("ix_coverage_locations_city", table_name="coverage_locations")
    op.drop_table("coverage_locations")
