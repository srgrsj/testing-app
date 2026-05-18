//
//  testingUITests.swift
//  testingUITests
//
//  Created by Sergei Zhukov on 17.05.2026.
//

import XCTest

final class testingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // Проверяет успешное создание продукта с валидными значениями из эквивалентного класса корректных данных.
    func testCreateProduct() throws {
        let productName = uniqueName("TestProduct")

        createProduct(
            name: productName,
            calories: "12",
            proteins: "12",
            fats: "12",
            carbs: "12"
        )

        XCTAssertTrue(app.staticTexts[productName].waitForExistence(timeout: 10))
    }

    // Проверяет создание продукта на нижней границе БЖУ: калории, белки, жиры и углеводы равны 0.
    func testCreateProductWithBoundaryMinimumNutritionValues() throws {
        let productName = uniqueName("BoundaryMinProduct")

        createProduct(
            name: productName,
            calories: "0",
            proteins: "0",
            fats: "0",
            carbs: "0"
        )

        XCTAssertTrue(app.staticTexts[productName].waitForExistence(timeout: 10))
    }

    // Проверяет создание продукта со значениями сразу выше нижней границы: дробные БЖУ по 0.1.
    func testCreateProductWithBoundaryFractionNutritionValues() throws {
        let productName = uniqueName("BoundaryFractionProduct")

        createProduct(
            name: productName,
            calories: "0.1",
            proteins: "0.1",
            fats: "0.1",
            carbs: "0.1"
        )

        XCTAssertTrue(app.staticTexts[productName].waitForExistence(timeout: 10))
    }

    // Проверяет, что продукт нельзя сохранить с пустым названием.
    func testProductSaveButtonIsDisabledForEmptyName() throws {
        openProductEditor()

        let createButton = app.buttons["productEditorSaveButton"]

        XCTAssertTrue(app.textFields["productNameField"].waitForExistence(timeout: 5))
        XCTAssertFalse(createButton.isEnabled)
    }

    // Проверяет отображение ошибки при попытке создать продукт без обязательных числовых полей БЖУ.
    func testProductShowsValidationErrorForMissingNutritionFields() throws {
        openProductEditor()
        typeText("InvalidProduct", into: app.textFields["productNameField"])

        app.buttons["productEditorSaveButton"].tap()

        XCTAssertTrue(app.textFields["productNameField"].waitForExistence(timeout: 5))
        scrollToElement(app.staticTexts["createProductError"])
        XCTAssertTrue(app.staticTexts["createProductError"].exists)
    }

    // Проверяет успешное редактирование продукта с валидными значениями из эквивалентного класса корректных данных.
    func testEditProductWithEquivalentValidValues() throws {
        let originalName = uniqueName("EditableProduct")
        let editedName = uniqueName("EditedProduct")
        createProduct(name: originalName, calories: "10", proteins: "1", fats: "2", carbs: "3")
        openProductDetails(named: originalName)

        let editProductButton = app.buttons["editProductButton"]
        XCTAssertTrue(editProductButton.waitForExistence(timeout: 10))
        editProductButton.tap()
        XCTAssertTrue(app.textFields["productNameField"].waitForExistence(timeout: 5))
        replaceText(in: app.textFields["productNameField"], with: editedName)
        replaceText(in: app.textFields["productCaloriesField"], with: "250")
        replaceText(in: app.textFields["productProteinsField"], with: "30")
        replaceText(in: app.textFields["productFatsField"], with: "15")
        replaceText(in: app.textFields["productCarbsField"], with: "40")

        app.buttons["productEditorSaveButton"].tap()

        XCTAssertTrue(staticTextContaining(editedName).waitForExistence(timeout: 10))
    }

    // Проверяет создание блюда на нижних допустимых границах: порция 1 г, ингредиент 1 г и БЖУ по 0.
    func testCreateDishWithBoundaryMinimumPortionAndNutritionValues() throws {
        let productName = uniqueName("DishBaseProduct")
        let dishName = uniqueName("BoundaryDish")
        createProduct(name: productName, calories: "1", proteins: "1", fats: "1", carbs: "1")
        openDishesTab()

        openDishEditor()
        typeText(dishName, into: app.textFields["dishNameField"])
        replaceText(in: app.textFields["dishPortionSizeField"], with: "1")
        replaceText(in: firstIngredientQuantityField(), with: "1")
        replaceText(in: app.textFields["dishCaloriesField"], with: "0")
        replaceText(in: app.textFields["dishProteinsField"], with: "0")
        replaceText(in: app.textFields["dishFatsField"], with: "0")
        replaceText(in: app.textFields["dishCarbsField"], with: "0")

        app.buttons["dishEditorSaveButton"].tap()

        XCTAssertTrue(app.staticTexts[dishName].waitForExistence(timeout: 10))
    }

    // Проверяет, что макрос категории в названии блюда обрабатывается и удаляется из отображаемого названия.
    func testDishNameMacroAssignsCategoryAndCleansName() throws {
        let productName = uniqueName("MacroBaseProduct")
        let dishName = uniqueName("MacroSoup")
        createProduct(name: productName, calories: "20", proteins: "2", fats: "2", carbs: "2")
        openDishesTab()

        openDishEditor()
        typeText("!суп \(dishName)", into: app.textFields["dishNameField"])
        replaceText(in: firstIngredientQuantityField(), with: "100")
        app.buttons["dishEditorSaveButton"].tap()

        XCTAssertTrue(app.staticTexts[dishName].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["!суп \(dishName)"].exists)

        openDishDetails(named: dishName)
        XCTAssertTrue(staticTextContaining("Суп").waitForExistence(timeout: 10))
    }

    // Проверяет ошибку на недопустимой границе количества ингредиента: 0 г.
    func testDishShowsErrorForZeroIngredientQuantityBoundary() throws {
        let productName = uniqueName("InvalidDishBaseProduct")
        createProduct(name: productName, calories: "20", proteins: "2", fats: "2", carbs: "2")
        openDishesTab()

        openDishEditor()
        typeText(uniqueName("InvalidDish"), into: app.textFields["dishNameField"])
        replaceText(in: firstIngredientQuantityField(), with: "0")
        app.buttons["dishEditorSaveButton"].tap()

        let quantityError = app.staticTexts["Количество каждого ингредиента должно быть больше 0"]
        scrollToElement(quantityError)
        XCTAssertTrue(quantityError.exists)
        
    }

    // Проверяет, что отмена создания продукта закрывает форму и не добавляет введенное название в список.
    func testCancelProductCreationDoesNotCreateProduct() throws {
        let productName = uniqueName("CancelledProduct")
        openProductsTab()
        openProductEditor()
        typeText(productName, into: app.textFields["productNameField"])

        app.buttons["productEditorCancelButton"].tap()

        XCTAssertTrue(app.buttons["createProductButton"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts[productName].exists)
    }

    // Проверяет, что блюдо нельзя сохранить с пустым названием.
    func testDishSaveButtonIsDisabledForEmptyName() throws {
        openDishesTab()
        openDishEditor()

        let saveButton = app.buttons["dishEditorSaveButton"]

        XCTAssertTrue(app.textFields["dishNameField"].waitForExistence(timeout: 5))
        XCTAssertFalse(saveButton.isEnabled)
    }

    // Проверяет, что отмена создания блюда закрывает форму и возвращает пользователя к списку блюд.
    func testCancelDishCreationReturnsToDishesList() throws {
        let dishName = uniqueName("CancelledDish")
        openDishesTab()
        openDishEditor()
        typeText(dishName, into: app.textFields["dishNameField"])

        app.buttons["dishEditorCancelButton"].tap()

        XCTAssertTrue(app.buttons["createDishButton"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts[dishName].exists)
    }

    // Проверяет, что экран фильтров продуктов открывается, сбрасывается и применяется без ошибки навигации.
    func testProductFiltersCanBeResetAndApplied() throws {
        openProductsTab()

        app.buttons["productsFiltersButton"].tap()
        XCTAssertTrue(app.buttons["productFiltersResetButton"].waitForExistence(timeout: 10))
        app.buttons["productFiltersResetButton"].tap()
        app.buttons["productFiltersApplyButton"].tap()

        XCTAssertTrue(app.buttons["createProductButton"].waitForExistence(timeout: 10))
    }

    // Проверяет, что экран фильтров блюд открывается, сбрасывается и применяется без ошибки навигации.
    func testDishFiltersCanBeResetAndApplied() throws {
        openDishesTab()

        app.buttons["dishesFiltersButton"].tap()
        XCTAssertTrue(app.buttons["dishFiltersResetButton"].waitForExistence(timeout: 10))
        app.buttons["dishFiltersResetButton"].tap()
        app.buttons["dishFiltersApplyButton"].tap()

        XCTAssertTrue(app.buttons["createDishButton"].waitForExistence(timeout: 10))
    }

    // Проверяет, что продукт, который используется в блюде, нельзя удалить.
    func testDeletingProductUsedInDishShowsError() throws {
        let productName = uniqueName("DeleteConflictProduct")
        let dishName = uniqueName("ConflictDish")
        createProduct(name: productName, calories: "100", proteins: "10", fats: "5", carbs: "15")
        openDishesTab()

        openDishEditor()
        typeText(dishName, into: app.textFields["dishNameField"])
        selectFirstIngredientProduct(named: productName)
        replaceText(in: firstIngredientQuantityField(), with: "100")
        app.buttons["dishEditorSaveButton"].tap()
        XCTAssertTrue(app.staticTexts[dishName].waitForExistence(timeout: 10))

        openProductsTab()
        let productTitle = app.staticTexts[productName]
        scrollToElement(productTitle, maxSwipes: 10)
        XCTAssertTrue(productTitle.exists)
        productTitle.swipeLeft()
        app.buttons["Удалить"].tap()

        XCTAssertTrue(app.alerts["Ошибка"].waitForExistence(timeout: 10))
        app.alerts["Ошибка"].buttons["OK"].tap()
        XCTAssertTrue(app.staticTexts[productName].waitForExistence(timeout: 10))
    }

    // Проверяет успешное редактирование блюда с валидными значениями из эквивалентного класса корректных данных.
    func testEditDishWithEquivalentValidValues() throws {
        let productName = uniqueName("EditDishBaseProduct")
        let originalName = uniqueName("EditableDish")
        let editedName = uniqueName("EditedDish")
        createProduct(name: productName, calories: "100", proteins: "10", fats: "5", carbs: "15")
        openDishesTab()
        createDish(name: originalName, portionSize: "100", ingredientQuantity: "100")
        openDishDetails(named: originalName)

        app.buttons["editDishButton"].tap()
        XCTAssertTrue(app.textFields["dishNameField"].waitForExistence(timeout: 5))
        replaceText(in: app.textFields["dishNameField"], with: editedName)
        replaceText(in: app.textFields["dishPortionSizeField"], with: "250")
        replaceText(in: firstIngredientQuantityField(), with: "250")
        replaceText(in: app.textFields["dishCaloriesField"], with: "300")
        replaceText(in: app.textFields["dishProteinsField"], with: "20")
        replaceText(in: app.textFields["dishFatsField"], with: "10")
        replaceText(in: app.textFields["dishCarbsField"], with: "30")

        app.buttons["dishEditorSaveButton"].tap()

        XCTAssertTrue(staticTextContaining(editedName).waitForExistence(timeout: 10))
    }

    private func createProduct(name: String, calories: String, proteins: String, fats: String, carbs: String) {
        openProductsTab()
        openProductEditor()
        typeText(name, into: app.textFields["productNameField"])
        typeText(calories, into: app.textFields["productCaloriesField"])
        typeText(proteins, into: app.textFields["productProteinsField"])
        typeText(fats, into: app.textFields["productFatsField"])
        typeText(carbs, into: app.textFields["productCarbsField"])
        app.buttons["productEditorSaveButton"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 10))
    }

    private func createDish(name: String, portionSize: String, ingredientQuantity: String) {
        openDishEditor()
        typeText(name, into: app.textFields["dishNameField"])
        replaceText(in: app.textFields["dishPortionSizeField"], with: portionSize)
        replaceText(in: firstIngredientQuantityField(), with: ingredientQuantity)
        app.buttons["dishEditorSaveButton"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 10))
    }

    private func openProductsTab() {
        let productsTab = app.tabBars.buttons["Продукты"]
        XCTAssertTrue(productsTab.waitForExistence(timeout: 10))
        productsTab.tap()
        XCTAssertTrue(app.buttons["createProductButton"].waitForExistence(timeout: 10))
    }

    private func openDishesTab() {
        let dishesTab = app.tabBars.buttons["Блюда"]
        XCTAssertTrue(dishesTab.waitForExistence(timeout: 10))
        dishesTab.tap()
        XCTAssertTrue(app.buttons["createDishButton"].waitForExistence(timeout: 10))
    }

    private func openProductEditor() {
        let createProductButton = app.buttons["createProductButton"]
        XCTAssertTrue(createProductButton.waitForExistence(timeout: 10))
        XCTAssertTrue(createProductButton.isHittable)
        createProductButton.tap()
        XCTAssertTrue(app.textFields["productNameField"].waitForExistence(timeout: 10))
    }

    private func openDishEditor() {
        let createDishButton = app.buttons["createDishButton"]
        XCTAssertTrue(createDishButton.waitForExistence(timeout: 10))
        XCTAssertTrue(createDishButton.isHittable)
        createDishButton.tap()
        XCTAssertTrue(app.textFields["dishNameField"].waitForExistence(timeout: 10))
    }

    private func openProductDetails(named name: String) {
        let productTitle = app.staticTexts[name]
        XCTAssertTrue(productTitle.waitForExistence(timeout: 10))
        productTitle.tap()
        XCTAssertTrue(app.buttons["editProductButton"].waitForExistence(timeout: 10))
    }

    private func openDishDetails(named name: String) {
        let dishTitle = app.staticTexts[name]
        XCTAssertTrue(dishTitle.waitForExistence(timeout: 10))
        dishTitle.tap()
        XCTAssertTrue(app.buttons["editDishButton"].waitForExistence(timeout: 10))
    }

    private func firstIngredientQuantityField() -> XCUIElement {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "dishIngredientQuantityField_")
        let field = app.textFields.matching(predicate).element(boundBy: 0)
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        return field
    }

    private func selectFirstIngredientProduct(named productName: String) {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "dishIngredientProductPicker_")
        let picker = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10))

        if app.staticTexts[productName].exists {
            return
        }

        picker.tap()
        let productOption = app.staticTexts[productName]
        XCTAssertTrue(productOption.waitForExistence(timeout: 10))
        productOption.tap()
    }

    private func typeText(_ text: String, into field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(text)
    }

    private func replaceText(in field: XCUIElement, with text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()

        if let value = field.value as? String, !value.isEmpty {
            let deleteSequence = String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)
            field.typeText(deleteSequence)
        }

        field.typeText(text)
    }

    private func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 6) {
        if element.waitForExistence(timeout: 1) {
            return
        }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.waitForExistence(timeout: 1) {
                return
            }
        }
    }

    private func staticTextContaining(_ text: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch
    }

    private func uniqueName(_ prefix: String) -> String {
        "\(prefix)_\(Int(Date().timeIntervalSince1970 * 1000))"
    }
}

