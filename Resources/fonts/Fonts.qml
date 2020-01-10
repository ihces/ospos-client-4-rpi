pragma Singleton

import QtQuick 2.0

Item {
    id: fonts

    readonly property FontLoader fontAwesomeRegular: FontLoader {
        source: "./fontawesome/Font-Awesome-5-Brands-Regular-400.otf"
    }
    readonly property FontLoader fontAwesomeSolid: FontLoader {
        source: "./fontawesome/Font-Awesome-5-Free-Solid-900.otf"
    }
    readonly property FontLoader fontAwesomeBrands: FontLoader {
        source: "./fontawesome/Font-Awesome-5-Brands-Regular-400.otf"
    }

    readonly property FontLoader fontProductRegular: FontLoader {
        source: "./product/Product-Sans-Regular.otf"
    }

    readonly property FontLoader fontRubikRegular: FontLoader {
        source: "./product/Rubik-Regular.ttf"
    }

    readonly property FontLoader fontIBMPlexMonoRegular: FontLoader {
        source: "./product/IBMPlexMono-Regular.ttf"
    }

    readonly property FontLoader fontIBMPlexMonoSemiBold: FontLoader {
        source: "./product/IBMPlexMono-SemiBold.ttf"
    }
    readonly property FontLoader fontTekoRegular: FontLoader {
        source: "./product/Teko-Regular.ttf"
    }

    readonly property FontLoader fontBarlowRegular: FontLoader {
        source: "./product/BarlowCondensed-Regular.ttf"
    }

    readonly property FontLoader fontPlayRegular: FontLoader {
        source: "./product/Play-Regular.ttf"
    }

    readonly property FontLoader fontOrbitronRegular: FontLoader {
        source: "./product/Orbitron-Regular.ttf"
    }

    readonly property FontLoader fontBlackOpsOneRegular: FontLoader {
        source: "./product/BlackOpsOne-Regular.ttf"
    }

    readonly property FontLoader fontFondamentoRegular: FontLoader {
        source: "./product/Fondamento-Regular.ttf"
    }

    readonly property FontLoader fontTomorrowRegular: FontLoader {
        source: "./product/Tomorrow-Regular.ttf"
    }

    readonly property FontLoader fontTomorrowSemiBold: FontLoader {
        source: "./product/Tomorrow-SemiBold.ttf"
    }

    readonly property string icons: fonts.fontAwesomeRegular.name
    readonly property string brands: fonts.fontAwesomeBrands.name
}
