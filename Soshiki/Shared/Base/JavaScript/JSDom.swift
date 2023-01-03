//
//  JSDOM.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import JavaScriptCore
import SwiftSoup

class JSDom {
    var documentReferences: [String: (document: Document, references: [String])] = [:]
    var elementReferences: [String: (element: Element, reference: String)] = [:]

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func inject(into context: JSContext) {
        let dom = JSDom()

        // MARK: - Base Functions

        context.globalObject.setObject({ html in
            let reference = String.random()
            dom.documentReferences[reference] = (document: (try? SwiftSoup.parse(html)) ?? Document(""), references: [])
            return reference
        } as @convention(block) (String) -> String, forKeyedSubscript: "__document_parse")
        context.globalObject.setObject({ ref in
            if let value = dom.documentReferences.removeValue(forKey: ref) {
                value.references.forEach({ dom.elementReferences.removeValue(forKey: $0) })
            }
        } as @convention(block) (String) -> Void, forKeyedSubscript: "__document_free")

        // MARK: - Document Functions

        context.globalObject.setObject({ ref, id in
            guard let document = dom.documentReferences[ref],
                  let element = try? document.document.getElementById(id) else { return "" }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: element, reference: ref)
            dom.documentReferences[ref]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String, String) -> String, forKeyedSubscript: "__document_getElementById")
        context.globalObject.setObject({ ref, className in
            guard let document = dom.documentReferences[ref],
                  let elements = try? document.document.getElementsByClass(className) else { return [] }
            var elementRefs: [String] = []
            for element in elements {
                let elementRef = String.random()
                dom.elementReferences[elementRef] = (element: element, reference: ref)
                dom.documentReferences[ref]?.references.append(elementRef)
                elementRefs.append(elementRef)
            }
            return elementRefs
        } as @convention(block) (String, String) -> [String], forKeyedSubscript: "__document_getElementsByClassName")
        context.globalObject.setObject({ ref, tagName in
            guard let document = dom.documentReferences[ref],
                  let elements = try? document.document.getElementsByTag(tagName) else { return [] }
            var elementRefs: [String] = []
            for element in elements {
                let elementRef = String.random()
                dom.elementReferences[elementRef] = (element: element, reference: ref)
                dom.documentReferences[ref]?.references.append(elementRef)
                elementRefs.append(elementRef)
            }
            return elementRefs
        } as @convention(block) (String, String) -> [String], forKeyedSubscript: "__document_getElementsByTagName")
        context.globalObject.setObject({ ref, selector in
            guard let document = dom.documentReferences[ref],
                  let element = try? document.document.select(selector).first() else { return "" }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: element, reference: ref)
            dom.documentReferences[ref]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String, String) -> String, forKeyedSubscript: "__document_querySelector")
        context.globalObject.setObject({ ref, selector in
            guard let document = dom.documentReferences[ref],
                  let elements = try? document.document.select(selector) else { return [] }
            var elementRefs: [String] = []
            for element in elements {
                let elementRef = String.random()
                dom.elementReferences[elementRef] = (element: element, reference: ref)
                dom.documentReferences[ref]?.references.append(elementRef)
                elementRefs.append(elementRef)
            }
            return elementRefs
        } as @convention(block) (String, String) -> [String], forKeyedSubscript: "__document_querySelectorAll")
        context.globalObject.setObject({ ref in
            guard let document = dom.documentReferences[ref] else { return [] }
            let elements = document.document.children()
            var elementRefs: [String] = []
            for element in elements {
                let elementRef = String.random()
                dom.elementReferences[elementRef] = (element: element, reference: ref)
                dom.documentReferences[ref]?.references.append(elementRef)
                elementRefs.append(elementRef)
            }
            return elementRefs
        } as @convention(block) (String) -> [String], forKeyedSubscript: "__document_children")
        context.globalObject.setObject({ ref in
            guard let document = dom.documentReferences[ref],
                  let element = document.document.head() else { return "" }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: element, reference: ref)
            dom.documentReferences[ref]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String) -> String, forKeyedSubscript: "__document_head")
        context.globalObject.setObject({ ref in
            guard let document = dom.documentReferences[ref],
                  let element = document.document.body() else { return "" }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: element, reference: ref)
            dom.documentReferences[ref]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String) -> String, forKeyedSubscript: "__document_body")
        context.globalObject.setObject({ ref in
            guard let document = dom.documentReferences[ref],
                  let element = try? document.document.select("html").first() else { return "" }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: element, reference: ref)
            dom.documentReferences[ref]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String) -> String, forKeyedSubscript: "__document_root")

        // MARK: - Element Functions

        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref],
                  let attributes = element.element.getAttributes() else { return [:] }
            var attributesDict: [String: String] = [:]
            for attribute in attributes {
                attributesDict[attribute.getKey()] = attribute.getValue()
            }
            return attributesDict
        } as @convention(block) (String) -> [String: String], forKeyedSubscript: "__element_attributes")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return 0 }
            return element.element.children().count
        } as @convention(block) (String) -> Int, forKeyedSubscript: "__element_childElementCount")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return [] }
            let children = element.element.children()
            var elementRefs: [String] = []
            for child in children {
                let reference = String.random()
                dom.elementReferences[reference] = (element: child, reference: element.reference)
                dom.documentReferences[element.reference]?.references.append(reference)
                elementRefs.append(reference)
            }
            return elementRefs
        } as @convention(block) (String) -> [String], forKeyedSubscript: "__element_children")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return [] }
            return (try? element.element.classNames().map({ $0 })) ?? []
        } as @convention(block) (String) -> [String], forKeyedSubscript: "__element_classList")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return "" }
            return (try? element.element.className()) ?? ""
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_className")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref],
                  let child = element.element.children().first() else { return "" }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: child, reference: element.reference)
            dom.documentReferences[element.reference]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_firstElementChild")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref],
                  let child = element.element.children().last() else { return "" }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: child, reference: element.reference)
            dom.documentReferences[element.reference]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_lastElementChild")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return "" }
            return element.element.id()
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_id")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return "" }
            return (try? element.element.html()) ?? ""
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_innerHTML")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return "" }
            return (try? element.element.outerHtml()) ?? ""
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_className")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref],
                  let child = try? element.element.previousElementSibling() else { return nil }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: child, reference: element.reference)
            dom.documentReferences[element.reference]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String) -> String?, forKeyedSubscript: "__element_previousElementSibling")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref],
                  let child = try? element.element.nextElementSibling() else { return nil }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: child, reference: element.reference)
            dom.documentReferences[element.reference]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String) -> String?, forKeyedSubscript: "__element_nextElementSibling")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return "" }
            return element.element.tagName()
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_tagName")
        context.globalObject.setObject({ ref, name in
            guard let element = dom.elementReferences[ref] else { return "" }
            return (try? element.element.attr(name)) ?? ""
        } as @convention(block) (String, String) -> String, forKeyedSubscript: "__element_getAttribute")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return [] }
            return element.element.getAttributes()?.asList().map({ $0.getKey() }) ?? []
        } as @convention(block) (String) -> [String], forKeyedSubscript: "__element_getAttributeNames")
        context.globalObject.setObject({ ref, id in
            guard let element = dom.elementReferences[ref],
                  let child = try? element.element.getElementById(id) else { return "" }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: child, reference: element.reference)
            dom.documentReferences[element.reference]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String, String) -> String, forKeyedSubscript: "__element_getElementById")
        context.globalObject.setObject({ ref, name in
            guard let element = dom.elementReferences[ref],
                  let children = try? element.element.getElementsByClass(name) else { return [] }
            var elementRefs: [String] = []
            for child in children {
                let reference = String.random()
                dom.elementReferences[reference] = (element: child, reference: element.reference)
                dom.documentReferences[element.reference]?.references.append(reference)
                elementRefs.append(reference)
            }
            return elementRefs
        } as @convention(block) (String, String) -> [String], forKeyedSubscript: "__element_getElementsByClassName")
        context.globalObject.setObject({ ref, name in
            guard let element = dom.elementReferences[ref],
                  let children = try? element.element.getElementsByTag(name) else { return [] }
            var elementRefs: [String] = []
            for child in children {
                let reference = String.random()
                dom.elementReferences[reference] = (element: child, reference: element.reference)
                dom.documentReferences[element.reference]?.references.append(reference)
                elementRefs.append(reference)
            }
            return elementRefs
        } as @convention(block) (String, String) -> [String], forKeyedSubscript: "__element_getElementsByTagName")
        context.globalObject.setObject({ ref, selector in
            guard let element = dom.elementReferences[ref],
                  let child = try? element.element.select(selector).first() else { return "" }
            let elementRef = String.random()
            dom.elementReferences[elementRef] = (element: child, reference: element.reference)
            dom.documentReferences[element.reference]?.references.append(elementRef)
            return elementRef
        } as @convention(block) (String, String) -> String, forKeyedSubscript: "__element_querySelector")
        context.globalObject.setObject({ ref, selector in
            guard let element = dom.elementReferences[ref],
                  let children = try? element.element.select(selector) else { return [] }
            var elementRefs: [String] = []
            for child in children {
                let reference = String.random()
                dom.elementReferences[reference] = (element: child, reference: element.reference)
                dom.documentReferences[element.reference]?.references.append(reference)
                elementRefs.append(reference)
            }
            return elementRefs
        } as @convention(block) (String, String) -> [String], forKeyedSubscript: "__element_querySelectorAll")
        context.globalObject.setObject({ ref, name in
            guard let element = dom.elementReferences[ref] else { return false }
            return element.element.hasAttr(name)
        } as @convention(block) (String, String) -> Bool, forKeyedSubscript: "__element_hasAttribute")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return false }
            return !(element.element.getAttributes()?.asList().isEmpty ?? true)
        } as @convention(block) (String) -> Bool, forKeyedSubscript: "__element_hasAttributes")
        context.globalObject.setObject({ ref, selector in
            guard let element = dom.elementReferences[ref] else { return false }
            return (try? element.element.select(selector).contains(element.element)) ?? false
        } as @convention(block) (String, String) -> Bool, forKeyedSubscript: "__element_matches")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return "" }
            return (try? element.element.text()) ?? ""
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_innerText")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return "" }
            return (try? element.element.text()) ?? ""
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_outerText")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return "" }
            return (try? element.element.attr("style")) ?? ""
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_style")
        context.globalObject.setObject({ ref in
            guard let element = dom.elementReferences[ref] else { return "" }
            return (try? element.element.attr("title")) ?? ""
        } as @convention(block) (String) -> String, forKeyedSubscript: "__element_title")
    }
}
