
(function() {
    
window.SCST_DMV = {};

SCST_DMV.translations = {} 
SCST_DMV.resourceName = "scriptstorm_dmv";
SCST_DMV.licenses = []
SCST_DMV.currentLicense = {}
SCST_DMV.questions = []
SCST_DMV.questionIndex = 0

const { animate, scroll } = Motion

Handlebars.registerHelper("isHidden", function(v1, v2, options)
{
    return v1 != v2 ? 'hidden' : '';
});

SCST_DMV.getRandomQuestions = function (questions, amount) {

    const shuffle = (array) => {
        let currentIndex = array.length;
      
        // While there remain elements to shuffle...
        while (currentIndex != 0) {
      
          // Pick a remaining element...
          let randomIndex = Math.floor(Math.random() * currentIndex);
          currentIndex--;
      
          // And swap it with the current element.
          [array[currentIndex], array[randomIndex]] = [
            array[randomIndex], array[currentIndex]];
        }

        return array
    }

    const shuffledDeck = shuffle([...questions])
    return shuffledDeck.length > amount ? shuffledDeck.slice(0,amount) : shuffledDeck
}

SCST_DMV.close = function () {
    SCST_DMV.currentLicense = {}
    let menuContainer = document.querySelectorAll("#scst-dmv")[0];
    menuContainer.innerHTML = "";

    try {
        fetch(`http://${SCST_DMV.resourceName}/close`, {
            method: 'POST',
        }).catch((err) => console.warn(err))
    }
    catch(err) {
        console.warn(err)
    }
}

SCST_DMV.initDrivingTest = function (vehicleType) {
    SCST_DMV.close()
    try {
        fetch(`http://${SCST_DMV.resourceName}/initDriving`, {
            method: 'POST',
            body: JSON.stringify({ type: vehicleType})
        }).catch((err) => console.warn(err))
    }
    catch(err) {
        console.warn(err)
    }
}

SCST_DMV.registerClose = function() {
    document.onkeydown = function(event) {
        if(event.key == 'Escape') {
            SCST_DMV.close()
        }
    }
}

SCST_DMV.onFailExam = function(vechicleType) {
    try {
        fetch(`http://${SCST_DMV.resourceName}/failExam`, {
            method: 'POST',
            body: JSON.stringify({ type: vechicleType})
        })
        .then(a => a.json())
        .catch((err) => console.warn(err))
    }
    catch(err) {
        console.warn(err)
    }
}

SCST_DMV.onPassExam = function(vechicleType) {
    try {
        fetch(`http://${SCST_DMV.resourceName}/passExam`, {
            method: 'POST',
            body: JSON.stringify({ type: vechicleType})
        })
        .then(a => a.json())
        .catch((err) => console.warn(err))
    }
    catch(err) {
        console.warn(err)
    }
}

SCST_DMV.onSelectLicense = function (index) {
    if(!!SCST_DMV.licenses && SCST_DMV.licenses[index] && !SCST_DMV.licenses[index].disabled) {
        try {
            fetch(`http://${SCST_DMV.resourceName}/handlePay`, {
                method: 'POST',
                body: JSON.stringify({ type: SCST_DMV.licenses[index].vehicleType})
            })
            .then(a => a.json())
            .then((data) => {
                if(data) {
                    SCST_DMV.currentLicense = SCST_DMV.licenses[index]
                    SCST_DMV.openLicenseMenu(SCST_DMV.licenses[index])
                }
            })
            .catch((err) => console.warn(err))
        }
        catch(err) {
            console.warn(err)
        }
    }
}

SCST_DMV.onSelectAnswer = function (optionIndex) {

    const progressBar = document.querySelector('#scst__progressbar')
    const progress = progressBar?.querySelector('.scst__progress div')
    const progressText = progressBar?.querySelector('span')
    SCST_DMV.questions[parseInt(SCST_DMV.questionIndex)].options[parseInt(optionIndex)].selected = true;

    const oldQuestionIndex = SCST_DMV.questionIndex
    SCST_DMV.questionIndex++

    if(!!progressBar && !!progress
        && SCST_DMV.questionIndex < SCST_DMV.questions.length
    ) {
        const newWidth = (100 / SCST_DMV.questions.length) * (SCST_DMV.questionIndex + 1);
        animate(progress, 
            { width: `${newWidth}%`, },
        );
        progressText.innerHTML = `${SCST_DMV.questionIndex + 1}/${ SCST_DMV.questions.length}`
    }

    if(SCST_DMV.questionIndex < SCST_DMV.questions.length) {
        const questions = document.querySelectorAll('.scst__question');
        const current = questions[oldQuestionIndex];

        animate(current, 
            {transform: 'translateX(-150%)' },
            {duration: 0.3 }
        );
        animate(questions[SCST_DMV.questionIndex], 
            { transform: 'translateX(0%)' },
            { delay: 0.3}
        );
    }
    else {
        const correctQuestions = SCST_DMV.questions.filter((q) => q.options.filter((opt) => opt.selected && opt.correct).length > 0)
        const incorrectQuestions = SCST_DMV.questions.filter((q) => q.options.filter((opt) => opt.selected && !opt.correct).length > 0)

        if(correctQuestions.length < SCST_DMV.currentLicense.minimumCorrectExam) {
            //Failed
            SCST_DMV.onFailExam(SCST_DMV.currentLicense.vehicleType)
            SCST_DMV.openResultMenu(false, correctQuestions.length, incorrectQuestions)
        }
        else {
            //Success
            SCST_DMV.onPassExam(SCST_DMV.currentLicense.vehicleType)
            SCST_DMV.openResultMenu(true, correctQuestions.length, incorrectQuestions)
        }
    }
}

SCST_DMV.openStartMenu = function(data) {
    SCST_DMV.registerClose()
    SCST_DMV.licenses = []
    let menuContainer = document.querySelectorAll("#scst-dmv")[0];
    menuContainer.innerHTML = "";

    let baseTemplateContent = document.querySelectorAll("#scst-dmv-base-template")[0].innerHTML;
    const baseTemplate = Handlebars.compile(baseTemplateContent);

    let startMenuTemplateContent = document.querySelectorAll("#scst-dmv-start-template")[0].innerHTML;
    const startMenuTemplate = Handlebars.compile(startMenuTemplateContent);

    let itemCardTemplateContent = document.querySelectorAll("#scst-dmv-item-template")[0].innerHTML;
    const itemCardTemplate = Handlebars.compile(itemCardTemplateContent);

    let menuContent = ''
    if(!!data.availableLicenses) {
        Object.keys(data.availableLicenses).forEach((licenseType, index) => {
            const license = data.availableLicenses[licenseType]
            let disabled = false 
            let failed = false 
            let passedExam = false

            if(!!data.player.licenses && data.player.licenses.length > 0) {
                if(data.player.licenses.indexOf(licenseType.toLocaleLowerCase()) <= -1) {
                    disabled = true
                }
                if(!!license.prerequiredLicense && data.player.licenses.indexOf(license.prerequiredLicense) <= -1) {
                    disabled = true
                }
            }
            else if(license.prerequiredLicense && license.prerequiredLicense.length > 0 && 
                (!data.player.licenses || (!!data.player.licenses && data.player.licenses.length == 0))) {
                disabled = true
            }
            else if(!!data.player.startedTrials && !!data.player.startedTrials[licenseType.toLocaleLowerCase()]) {
                if(data.player.startedTrials[licenseType.toLocaleLowerCase()]["Exam"]["Trials"] >= data.maxRetries.exam) {
                    disabled = true
                    failed = true 
                }

                if(data.player.startedTrials[licenseType.toLocaleLowerCase()]["Practical"]["Trials"] >= data.maxRetries.practical) {
                    disabled = true
                    failed = true 
                }

                if(data.player.startedTrials[licenseType.toLocaleLowerCase()]["Exam"]["Passed"]) {
                    passedExam = true
                }
            }

            const item = {
                id: index,
                bgImage: 'img/card_background.png',
                image: `img/${licenseType}.png`,
                headline: licenseType,
                subTitle: SCST_DMV.translations?.license ?? 'License',
                price: license.price,
                passedExam: passedExam,
                vehicleType: licenseType.toLocaleLowerCase(),
                questions: license.questions,
                prerequiredLicense: license.prerequiredLicense,
                questionnaireAmount: license.questionnaireAmount,
                minimumCorrectExam: license.minimumCorrectExam,
                disabled: disabled,
                failed: failed,
                footerText: license.prerequiredLicense ? (SCST_DMV.translations?.prerequiredLicense ?? '').replace('$$', license.prerequiredLicense) : '',
            }
            SCST_DMV.licenses.push(item)
            menuContent += itemCardTemplate({...item, index: index})
        });
    }

    const startContent = startMenuTemplate({ content: menuContent, translations: SCST_DMV.translations });
    const content = baseTemplate({ content: startContent, translations: SCST_DMV.translations });
    menuContainer.innerHTML = content; 
}

SCST_DMV.openLicenseMenu = function(license) {
    let container = document.querySelectorAll(".scst__main__content")[0];
    container.innerHTML = "";

    let licenseMenuTemplateContent = document.querySelectorAll("#scst-dmv-license-template")[0].innerHTML;
    const licenseMenuTemplate = Handlebars.compile(licenseMenuTemplateContent);
    
    const mainContent = licenseMenuTemplate({license: license, translations: SCST_DMV.translations})

    container.innerHTML = mainContent; 
}

SCST_DMV.openQuestionsMenu = function() {

    if(!!SCST_DMV.currentLicense && SCST_DMV.currentLicense.questions) {
        SCST_DMV.questions = SCST_DMV.getRandomQuestions(SCST_DMV.currentLicense.questions, SCST_DMV.currentLicense.questionnaireAmount ?? 10)
        SCST_DMV.questionIndex = 0
        let container = document.querySelectorAll(".scst__main__content")[0];
        container.innerHTML = "";

        let questionBaseTemplateContent = document.querySelectorAll("#scst-dmv-questions-base-template")[0].innerHTML;
        const questionsBaseMenuTemplate = Handlebars.compile(questionBaseTemplateContent);

        let questionTemplateContent = document.querySelectorAll("#scst-dmv-question-template")[0].innerHTML;
        const questionsTemplate = Handlebars.compile(questionTemplateContent);

        let questionContent = '';

        SCST_DMV.questions.forEach((q, index) => {
            q.options.forEach((opt) => opt.selected = false)
            questionContent += questionsTemplate({question: {
                ...q,
                text: `${index + 1}. ${q.text}`,
                bgImage: 'img/card_background.png',
                bgText: q.image ? '' : '?',
                image:  q.image,
                id: index,
            }, index: index,  currentIndex: SCST_DMV.questionIndex })
        })

        const mainContent = questionsBaseMenuTemplate({
            content: questionContent,
            currentIndex: SCST_DMV.questionIndex + 1,
            translations: SCST_DMV.translations,
            total: SCST_DMV.questions.length,
            progressWidth: `${(100/SCST_DMV.questions.length) * (SCST_DMV.questionIndex + 1)}%`
        })

        container.innerHTML = mainContent; 
    }
}

SCST_DMV.openResultMenu = function(passed, numCorrect,incorrectQuestions) {
    let container = document.querySelectorAll(".scst__main__content")[0];
    container.innerHTML = "";

    let resultTemplateContent = document.querySelectorAll("#scst-dmv-result-template")[0].innerHTML;
    const resultTemplate = Handlebars.compile(resultTemplateContent);

    const mainContent = resultTemplate({
        translations: SCST_DMV.translations,
        total: SCST_DMV.questions.length,
        bgImage: 'img/card_background.png',
        result: {
            image: passed ? 'img/passed.svg' : 'img/failed.svg',
            incorrectQuestions,
            numSuccess: numCorrect,
            headline: passed ? SCST_DMV.translations.youPassed : SCST_DMV.translations.youFailed,
            status: passed ? 'passed' : 'failed',
            success: passed
        }
    })

    container.innerHTML = mainContent; 
}

SCST_DMV.startDrivingTest = function() {
    if(SCST_DMV.currentLicense) {
        SCST_DMV.initDrivingTest(SCST_DMV.currentLicense.vehicleType)
    }
}

SCST_DMV.openDrivingResultMenu = function(data) {
    SCST_DMV.registerClose()
}

SCST_DMV.openDrivingOverlay = function(data) {
}

/*
CAMI_MENU.open = function(options, x, y) {
    CAMI_MENU.options = options; 
    CAMI_MENU.positionX = x;
    CAMI_MENU.positionY = y;

    CAMI_MENU.setupBackIndexes(CAMI_MENU.options)
    CAMI_MENU.initMenu();
    document.onkeydown = function(event) {
        if(event.key == 'Escape') {
            CAMI_MENU.close()
        }
    }
}

CAMI_MENU.close = function () {
    delete CAMI_MENU.options;
    delete CAMI_MENU.currentOptions;
    try {
        fetch(`http://${CAMI_MENU.ResourceName}/menu_close`, {
            method: 'POST',
        }).catch((err) => console.warn(err))
    }
    catch(err) {
        console.warn(err)
    }

    CAMI_MENU.initMenu();
}

CAMI_MENU.setupBackIndexes = function(items, backIndex) {
    if(items) {
        items.forEach((item, index) => {
            if(item.options) {
                item.backIndex = backIndex ? backIndex : "[root]" ;
                CAMI_MENU.setupBackIndexes(item.options, `${backIndex ? `${backIndex}.` : "[root]." }${index}`)
            }
            else {
                item.backIndex = backIndex;
            }
        })
    }
}

CAMI_MENU.initMenu = function () {

    CAMI_MENU.setupBackIndexes(CAMI_MENU.options)
    CAMI_MENU.currentOptions = CAMI_MENU.options;

    if(CAMI_MENU.currentOptions && CAMI_MENU.currentOptions.length > CAMI_MENU.maxItemsPer) {
        let items = CAMI_MENU.currentOptions.slice(0, CAMI_MENU.maxItemsPer - 1)
        CAMI_MENU.renderMenuItems(items, 0 , true, CAMI_MENU.maxItemsPer - 1)
    }
    else {
        CAMI_MENU.renderMenuItems(CAMI_MENU.options, 0)
    }

    let menuContainer = document.querySelectorAll("#menu")[0];
    menuContainer.style.left = CAMI_MENU.positionX * 100 + "%";
    menuContainer.style.top = CAMI_MENU.positionX * 100 + "%";
    menuContainer.style.marginLeft = "-" + (menuContainer.clientWidth / 2) + "px";
    menuContainer.style.marginTop = "-" + (menuContainer.clientHeight / 2) + "px";
}

CAMI_MENU.selectItem = function (item, index) {
    delete CAMI_MENU.options;
    delete CAMI_MENU.currentOptions;

    try {
        fetch(`http://${CAMI_MENU.ResourceName}/menu_select`, {
            method: 'POST',
            body: JSON.stringify({
                name: CAMI_MENU.name,
                item: {
                    index,
                    event: item.event,
                    position: item.backIndex
                }
            })
        }).catch((err) => console.warn(err))
    }
    catch(err) {
        console.warn(err)
    }

    CAMI_MENU.initMenu();
}

CAMI_MENU.onBack = function(backIndexes) {
    let options = CAMI_MENU.options;
    let item = options[0];

    if(backIndexes && backIndexes.length > 0) {
        if(backIndexes.indexOf('.') > -1) {
            let indexes = backIndexes.split('.')
            if(indexes) {
                options = CAMI_MENU.options
                indexes.forEach((currentIndex) => {
                    if(currentIndex.indexOf('root') > -1) {
                        options = CAMI_MENU.options
                    }
                    else {
                        let index = parseInt(currentIndex.replace('.'))
                        if(!!options[index]) {
                            item = options[index];
                            if(options[index].options) {
                                options = options[index].options;
                            }
                        }
                    }
                })
            }
        }
        else {
            if(backIndexes === "[root]") {
                options = CAMI_MENU.options
            }
            else {
                let index = parseInt(backIndexes)
                if(CAMI_MENU.options[index] && CAMI_MENU.options[index].options) {
                    item = CAMI_MENU.options[index];
                    options = CAMI_MENU.options[index].options;
                }
            }
        }
    }
    else {
        options = CAMI_MENU.options
    }

    CAMI_MENU.currentOptions = options;

    if(!!item) {
        CAMI_MENU.currentBackIndex = item.backIndex;
        CAMI_MENU.currentBackItem = item;

        if(options.length > CAMI_MENU.maxItemsPer) {
            let chunk = options.slice(0, CAMI_MENU.maxItemsPer - 1)
            CAMI_MENU.renderMenuItems(chunk,0, true, CAMI_MENU.maxItemsPer - 1, item.backIndex)
        }
        else {
            CAMI_MENU.renderMenuItems(options,0, false, 0,item.backIndex)
        }
    }
    else {
        if(options.length > CAMI_MENU.maxItemsPer) {
            let chunk = options.slice(0, CAMI_MENU.maxItemsPer - 1)
            CAMI_MENU.renderMenuItems(chunk,0, true, CAMI_MENU.maxItemsPer - 1)
        }
        else {
            CAMI_MENU.renderMenuItems(options,0, false, 0)
        }
    }
}

CAMI_MENU.onClick = function(index, isLoadmore) {
    if(CAMI_MENU.currentOptions) {
        if(isLoadmore) {
            let start = parseInt(index);
            let end = start + (CAMI_MENU.maxItemsPer - 1);
            let options = CAMI_MENU.currentOptions.slice(start, end)

            if(end > CAMI_MENU.currentOptions.length) {
                CAMI_MENU.renderMenuItems(options, start ,true, 0, CAMI_MENU.currentBackIndex)
            }
            else {
                CAMI_MENU.renderMenuItems(options, start ,true, end, CAMI_MENU.currentBackIndex)
            }
           
        }
        else {
            let itemIndex = parseInt(index)
            if(CAMI_MENU.currentOptions[itemIndex]) {
                let item = CAMI_MENU.currentOptions[itemIndex];
                if(item.options && item.options.length) {
                    CAMI_MENU.currentOptions = item.options;

                    if(item.options.length > CAMI_MENU.maxItemsPer) {
                        let options = CAMI_MENU.currentOptions.slice(0, CAMI_MENU.maxItemsPer - 1)
                        CAMI_MENU.renderMenuItems(options, 0 ,true, CAMI_MENU.maxItemsPer, item.backIndex)
                    }
                    else {
                        CAMI_MENU.renderMenuItems(item.options, 0, false, 0, item.backIndex)
                    }

                    CAMI_MENU.currentBackIndex = item.backIndex
                    CAMI_MENU.currentBackItem = item
                }
                else {
                    CAMI_MENU.selectItem(item, index)
                }
            }
        }
    }
}

CAMI_MENU.renderMenuItems = function (items, startIndex = 0, hasLoadMore = false, loadMoreIndex = 0, backIndex) {
    let menuContainer = document.querySelectorAll("#menu")[0];
    menuContainer.innerHTML = "";

    if(!items || (!!items && items.length <= 0)) {
        return;
    }

    let menuTemplateContent = document.querySelectorAll("#menu-template")[0].innerHTML;
    var menuTemplate = Handlebars.compile(menuTemplateContent);

    let menuItemTemplateContent = document.querySelectorAll("#menu-item-template")[0].innerHTML;
    var menuItemTemplate = Handlebars.compile(menuItemTemplateContent);

    let menuBackTemplateContent = document.querySelectorAll("#menu-back-template")[0].innerHTML;
    var menuBackTemplate = Handlebars.compile(menuBackTemplateContent);

    var menucontent = ''
    if(hasLoadMore) {
        menucontent += menuItemTemplate({
            text: ` ${CAMI_MENU.translations?.more ?? 'More'}..`, 
            loadMore: true,
            index: loadMoreIndex
        })
        items.forEach((item, i) =>
            {
                menucontent += menuItemTemplate({...item, index: startIndex + i})
            })
    }
    else {
        items.forEach((item, i) =>
        {
            menucontent += menuItemTemplate({...item, index: startIndex + i})
        })
    }

    if(backIndex && backIndex.length) {
        menucontent += menuBackTemplate({index: backIndex, text: CAMI_MENU.translations?.back ?? 'Back'})
    }

    var menu = menuTemplate({ content: menucontent });
    menuContainer.innerHTML = menu; 
}

*/
    window.onData = (eventData) => {

        if(eventData.showMenu) {
            if(eventData.translations) {
                SCST_DMV.translations = eventData.translations
            }

            switch(eventData.action) {
                case "openDrivingOverlay": {
                    SCST_DMV.openStartMenu(eventData.data);
                    break;
                }
                case "openStartMenu": {
                    SCST_DMV.openStartMenu(eventData.data);
                    break;
                }
                case "openDrivingResult": {
                    SCST_DMV.openDrivingResultMenu(eventData.data);
                    break;
                }
            }
        }
    }

    window.onload = function (e) {
        window.addEventListener("message", (event) => {
            onData(event.data);
        });
    };
})()