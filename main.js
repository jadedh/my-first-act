// This is the main Node.js source code file of your actor.
// It is referenced from the "scripts" section of the package.json file,
// so that it can be started by running "npm start".

const Apify = require('apify');
const cheerio = require('cheerio');
// const fetch = require('node-fetch');
const moment = require('moment');

Apify.main(async () => {
    console.log('Launching Puppeteer...');
    const browser = await Apify.launchPuppeteer();

    const page = await browser.newPage();

    await page.goto('https://shopee.co.th/-%E0%B8%A1%E0%B8%B5-2-%E0%B8%AA%E0%B8%B9%E0%B8%95%E0%B8%A3-Royal-Canin-Kitten-Pouch-(12-Pouches)-%E0%B9%82%E0%B8%A3%E0%B8%A2%E0%B8%B1%E0%B8%A5%E0%B8%84%E0%B8%B2%E0%B8%99%E0%B8%B4%E0%B8%99-%E0%B8%AD%E0%B8%B2%E0%B8%AB%E0%B8%B2%E0%B8%A3%E0%B9%80%E0%B8%9B%E0%B8%B5%E0%B8%A2%E0%B8%81%E0%B9%81%E0%B8%9A%E0%B8%9A%E0%B8%8B%E0%B8%AD%E0%B8%87-%E0%B8%AA%E0%B8%B3%E0%B8%AB%E0%B8%A3%E0%B8%B1%E0%B8%9A%E0%B8%A5%E0%B8%B9%E0%B8%81%E0%B9%81%E0%B8%A1%E0%B8%A7%E0%B8%AD%E0%B8%B2%E0%B8%A2%E0%B8%B8-4-12%E0%B9%80%E0%B8%94%E0%B8%B7%E0%B8%AD%E0%B8%99-%E0%B8%9A%E0%B8%A3%E0%B8%A3%E0%B8%88%E0%B8%B8-12%E0%B8%8B%E0%B8%AD%E0%B8%87-i.68023848.1133684293')
    
    const newPagePromise = new Promise(x => browser.once('targetcreated', target => x(target.page()))); 
    const popup = await newPagePromise;

    const [button] = await page.$x("//button[contains(., 'English')]");
    if (button) {
        await button.click();
    }


    // ดึงราคาเป้าหมาย หรือส่วนที่ต้องการ
    await page.waitForSelector('div[class = "pmmxKx"]');

    const content = await page.content();

    // นำผลลัพท์ที่ได้เข้า Cheerio io เพื่อให้เข้าถึงง่ายด้วยการเรียกใช้คล้ายๆ Jquery
    const $ = cheerio.load(content);

    const result = $('div[class = "pmmxKx"]');

    console.log(result.text())


    const payload = {
        price : result.text(),
        time : moment().format("LLLL")
    }
    
    const saveData = await fetch(
        "https://sheet.best/api/sheets/26dbf059-94fa-4567-916a-d7db3011b4f5",
        {
            method: "POST",
            headers: {
                Accept: "application/json",
                "Content-Type": "application/json",
                "X-Api-Key": "Xom_BvPqquWURXJ2H4mVIH8eW$2lxplFJx7TP!!CaTLeNbOpgfViZdm1bfxSSmeQ"
            },
            body: JSON.stringify(payload),
        }
    );

    if (saveData.status == 200) {
        await page.close();
        await browser.close();
    } else {
        console.log(saveData);
    }

    // Wait 30s to see Chromium works :)
    await new Promise(resolve => setTimeout(resolve, 20000));

    await browser.close();
});
