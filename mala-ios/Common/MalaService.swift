//
//  MalaService.swift
//  mala-ios
//
//  Created by 王新宇 on 2/25/16.
//  Copyright © 2016 Mala Online. All rights reserved.
//

import Foundation
import Alamofire

// MARK: Api
#if USE_PRD_SERVER
    public let MalaBaseUrl = "https://www.malalaoshi.com/api/v1"
#elseif USE_STAGE_SERVER
    public let MalaBaseUrl = "https://stage.malalaoshi.com/api/v1"
#else
    public let MalaBaseUrl = "https://dev.malalaoshi.com/api/v1"
#endif

public let MalaBaseURL = NSURL(string: MalaBaseUrl)!
public let gradeList = "/grades"
public let subjectList = "/subjects"
public let tagList = "/tags"
public let memberServiceList = "/memberservices"
public let teacherList = "/teachers"
public let sms = "/sms"
public let schools = "/schools"
public let weeklytimeslots = "/weeklytimeslots"
public let coupons = "/coupons"


// MARK: - typealias
typealias nullDictionary = [String: AnyObject]


// MARK: - Model
///  登陆用户信息结构体
struct LoginUser: CustomStringConvertible {
    let accessToken: String
    let userID: Int
    let parentID: Int?
    let profileID: Int
    let firstLogin: Bool?
    let avatarURLString: String?
    
    var description: String {
        return "LoginUser(accessToken: \(accessToken), userID: \(userID), parentID: \(parentID), profileID: \(profileID))" +
        ", firstLogin: \(firstLogin)), avatarURLString: \(avatarURLString))"
    }
}

///  SMS验证结果结构体
struct VerifyingSMS: CustomStringConvertible {
    let verified: String
    let first_login: String
    let token: String?
    let parent_id: String
    let reason: String?
    
    var description: String {
        return "VerifyingSMS(verified: \(verified), first_login: \(first_login), token: \(token), parent_id: \(parent_id), reason: \(reason))"
    }
}

///  个人账号信息结构体
struct profileInfo: CustomStringConvertible {
    let id: Int
    let gender: String?
    let avatar: String?
    
    var description: String {
        return "parentInfo(id: \(id), gender: \(gender), avatar: \(avatar)"
    }
}

///  家长账号信息结构体
struct parentInfo: CustomStringConvertible {
    let id: Int
    let studentName: String?
    let schoolName: String?
    
    var description: String {
        return "parentInfo(id: \(id), studentName: \(studentName), schoolName: \(schoolName)"
    }
}


// MARK: - Support Method
///  登陆成功后，获取个人信息和家长信息并保存到UserDefaults
func getInfoWhenLoginSuccess() {
    
    // 个人信息
    getAndSaveProfileInfo()
    
    // 家长信息
    getAndSaveParentInfo()
}

func getAndSaveProfileInfo() {
    let profileID = MalaUserDefaults.profileID.value ?? 0
    getProfileInfo(profileID, failureHandler: { (reason, errorMessage) -> Void in
        defaultFailureHandler(reason, errorMessage: errorMessage)
        // 错误处理
        if let errorMessage = errorMessage {
            println("MalaService - getProfileInfo Error \(errorMessage)")
        }
        },completion: { (profile) -> Void in
            println("保存Profile信息: \(profile)")
            saveProfileInfoToUserDefaults(profile)
    })
}

func getAndSaveParentInfo() {
    let parentID = MalaUserDefaults.parentID.value ?? 0
    getParentInfo(parentID, failureHandler: { (reason, errorMessage) -> Void in
        defaultFailureHandler(reason, errorMessage: errorMessage)
        // 错误处理
        if let errorMessage = errorMessage {
            println("MalaService - getParentInfo Error \(errorMessage)")
        }
        },completion: { (parent) -> Void in
            println("保存Parent信息: \(parent)")
            saveParentInfoToUserDefaults(parent)
    })
}


// MARK: - User

///  保存用户信息到UserDefaults
///  - parameter loginUser: 登陆用户模型
func saveTokenAndUserInfo(loginUser: LoginUser) {
    MalaUserDefaults.userID.value = loginUser.userID
    MalaUserDefaults.parentID.value = loginUser.parentID
    MalaUserDefaults.profileID.value = loginUser.profileID
    MalaUserDefaults.firstLogin.value = loginUser.firstLogin
    MalaUserDefaults.userAccessToken.value = loginUser.accessToken
}
////  保存个人信息到UserDefaults
///
///  - parameter profile: 个人信息模型
func saveProfileInfoToUserDefaults(profile: profileInfo) {
    MalaUserDefaults.gender.value = profile.gender
    MalaUserDefaults.avatar.value = profile.avatar
}
///  保存家长信息到UserDefaults
///
///  - parameter parent: 家长信息模型
func saveParentInfoToUserDefaults(parent: parentInfo) {
    MalaUserDefaults.studentName.value = parent.studentName
    MalaUserDefaults.schoolName.value = parent.schoolName
}

///  获取验证码
///
///  - parameter mobile:         手机号码
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func sendVerifyCodeOfMobile(mobile: String, failureHandler: ((Reason, String?) -> Void)?, completion: Bool -> Void) {
    /// 参数字典
    let requestParameters = [
        "action": VerifyCodeMethod.Send.rawValue,
        "phone": mobile
    ]
    /// 返回值解析器
    let parse: JSONDictionary -> Bool? = { data in
        
        if let result = data["sent"] as? Bool {
            return result
        }
        return false
    }
    
    /// 请求资源对象
    let resource = jsonResource(path: "/sms", method: .POST, requestParameters: requestParameters, parse: parse)
    
    /// 若未实现请求错误处理，进行默认的错误处理
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  验证手机号
///
///  - parameter mobile:         手机号码
///  - parameter verifyCode:     验证码
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func verifyMobile(mobile: String, verifyCode: String, failureHandler: ((Reason, String?) -> Void)?, completion: LoginUser -> Void) {
    let requestParameters = [
        "action": VerifyCodeMethod.Verify.rawValue,
        "phone": mobile,
        "code": verifyCode
    ]
    
    let parse: JSONDictionary -> LoginUser? = { data in
        return parseLoginUser(data)
    }
    
    let resource = jsonResource(path: "/sms", method: .POST, requestParameters: requestParameters, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  根据个人id获取个人信息
///
///  - parameter parentID:       个人
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getProfileInfo(profileID: Int, failureHandler: ((Reason, String?) -> Void)?, completion: profileInfo -> Void) {
    let parse: JSONDictionary -> profileInfo? = { data in
        return parseProfile(data)
    }
    
    let resource = authJsonResource(path: "/profiles/\(profileID)", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  根据家长id获取家长信息
///
///  - parameter parentID:       家长id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getParentInfo(parentID: Int, failureHandler: ((Reason, String?) -> Void)?, completion: parentInfo -> Void) {
    let parse: JSONDictionary -> parentInfo? = { data in
        return parseParent(data)
    }
    
    let resource = authJsonResource(path: "/parents/\(parentID)", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  上传用户头像
///
///  - parameter imageData:      头像
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func updateAvatarWithImageData(imageData: NSData, failureHandler: ((Reason, String?) -> Void)?, completion: Bool -> Void) {
    
    guard let token = MalaUserDefaults.userAccessToken.value else {
        println("updateAvatarWithImageData error - no token")
        return
    }
    
    guard let profileID = MalaUserDefaults.profileID.value else {
        println("updateAvatarWithImageData error - no profileID")
        return
    }
    
    let parameters: [String: String] = [
        "Authorization": "Token \(token)",
    ]
    
    let fileName = "avatar.jpg"
    
    Alamofire.upload(.PATCH, MalaBaseUrl + "/profiles/\(profileID)", headers: parameters, multipartFormData: { multipartFormData in
        
        multipartFormData.appendBodyPart(data: imageData, name: "avatar", fileName: fileName, mimeType: "image/jpeg")
        
        }, encodingCompletion: { encodingResult in
            println("encodingResult: \(encodingResult)")
            
            switch encodingResult {
                
            case .Success(let upload, _, _):
                
                upload.responseJSON(completionHandler: { response in
                    
                    guard let
                        data = response.data,
                        json = decodeJSON(data),
                        uploadResult = json["done"] as? String else {
                            failureHandler?(.CouldNotParseJSON, nil)
                            return
                    }
                    let result = (uploadResult == "true" ? true : false)
                    completion(result)
                })
                
            case .Failure(let encodingError):
                
                failureHandler?(.Other(nil), "\(encodingError)")
            }
    })
}

///  保存学生姓名
///
///  - parameter name:           姓名
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func saveStudentName(name: String, failureHandler: ((Reason, String?) -> Void)?, completion: Bool -> Void) {
    
    guard let parentID = MalaUserDefaults.parentID.value else {
        println("saveStudentSchoolName error - no profileID")
        return
    }
    
    let requestParameters = [
        "student_name": name,
    ]
    
    let parse: JSONDictionary -> Bool? = { data in
        if let result = data["done"] as? String where result == "true" {
            return true
        }else {
            return false
        }
    }
    
    let resource = authJsonResource(path: "/parents/\(parentID)", method: .PATCH, requestParameters: requestParameters, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  保存学生学校名称
///
///  - parameter name:           学校名称
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func saveStudentSchoolName(name: String, failureHandler: ((Reason, String?) -> Void)?, completion: Bool -> Void) {
    
    guard let parentID = MalaUserDefaults.parentID.value else {
        println("saveStudentSchoolName error - no profileID")
        return
    }
    
    let requestParameters = [
        "student_school_name": name,
    ]
    
    let parse: JSONDictionary -> Bool? = { data in
        if let result = data["done"] as? Bool {
            return result
        }
        return false
    }
    
    let resource = authJsonResource(path: "/parents/\(parentID)", method: .PATCH, requestParameters: requestParameters, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  优惠券列表解析函数
///
///  - parameter onlyValid:      是否只返回可用奖学金
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getCouponList(onlyValid: Bool = false, failureHandler: ((Reason, String?) -> Void)?, completion: [CouponModel] -> Void) {

    let parse: [JSONDictionary] -> [CouponModel] = { couponData in
        /// 解析优惠券JSON数组
        var coupons = [CouponModel]()
        for couponInfo in couponData {
            if let coupon = parseCoupon(couponInfo) {
                coupon.setupStatus()
                coupons.append(coupon)
            }
        }
        return coupons
    }
    
    ///  获取优惠券列表JSON对象
    headBlockedCoupons(onlyValid, failureHandler: failureHandler) { (jsonData) -> Void in
        if let coupons = jsonData["results"] as? [JSONDictionary] where coupons.count != 0 {
            completion(parse(coupons))
        }else {
            completion([])
        }
    }
}

///  获取优惠券列表
///
///  - parameter onlyValid:      是否只返回可用奖学金
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func headBlockedCoupons(onlyValid: Bool = false, failureHandler: ((Reason, String?) -> Void)?, completion: JSONDictionary -> Void) {
    
    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }
    let requestParameters = ["only_valid": String(onlyValid)]
    let resource = authJsonResource(path: "/coupons", method: .GET, requestParameters: requestParameters, parse: parse)
    apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
}

///  判断用户是否第一次购买此学科的课程
///
///  - parameter subjectID:      学科id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func isHasBeenEvaluatedWithSubject(subjectID: Int, failureHandler: ((Reason, String?) -> Void)?, completion: Bool -> Void) {

    let parse: JSONDictionary -> Bool = { data in
        if let result = data["evaluated"] as? Bool {
            // 服务器返回结果为：用户是否已经做过此学科的建档测评，是则代表非首次购买。故取反处理。
            return !result
        }
        return true
    }
    
    let resource = authJsonResource(path: "/subject/\(subjectID)/record", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取学生上课时间表
///
///  - parameter onlyPassed:     是否只获取已结束的课程
///  - parameter page:           页数
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getStudentCourseTable(onlyPassed: Bool = false, page: Int = 1, failureHandler: ((Reason, String?) -> Void)?, completion: [StudentCourseModel] -> Void) {
    
    let parse: JSONDictionary -> [StudentCourseModel] = { data in
        return parseStudentCourse(data)
    }
    let requestParameters = ["for_review": String(onlyPassed)]    
    let resource = authJsonResource(path: "/timeslots", method: .GET, requestParameters: requestParameters, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取用户订单列表
///
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getOrderList(page: Int = 1, failureHandler: ((Reason, String?) -> Void)?, completion: ([OrderForm], Int) -> Void) {
    
    let requestParameters = [
        "page": page,
        ]
    
    let parse: JSONDictionary -> ([OrderForm], Int) = { data in
        return parseOrderList(data)
    }
    
    let resource = authJsonResource(path: "/orders", method: .GET, requestParameters: requestParameters, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取用户新消息数量
///
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getUserNewMessageCount(failureHandler: ((Reason, String?) -> Void)?, completion: (order: Int, comment: Int) -> Void) {
    
    let parse: JSONDictionary -> (order: Int, comment: Int) = { data in
        if let
            order = data["unpaid_num"] as? Int,
            comment = data["tocomment_num"] as? Int {
            return (order, comment)
        }else {
            return (0, 0)
        }
    }
    
    let resource = authJsonResource(path: "/my_center", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取用户收藏老师列表
///
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getFavoriteTeachers(page: Int = 1, failureHandler: ((Reason, String?) -> Void)?, completion: ([TeacherModel], Int) -> Void) {
    
    let requestParameters = [
        "page": page,
        ]
    
    let parse: JSONDictionary -> ([TeacherModel], Int) = { data in
        return parseFavoriteTeacherResult(data)
    }
    
    let resource = authJsonResource(path: "/favorites", method: .GET, requestParameters: requestParameters, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  收藏老师
///
///  - parameter id:             老师id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func addFavoriteTeacher(id: Int, failureHandler: ((Reason, String?) -> Void)?, completion: Bool -> Void) {
    
    let requestParameters = [
        "teacher": id,
        ]
    
    let parse: JSONDictionary -> Bool = { data in
        return true
    }
    
    let resource = authJsonResource(path: "/favorites", method: .POST, requestParameters: requestParameters, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  取消收藏老师
///
///  - parameter id:             老师id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func removeFavoriteTeacher(id: Int, failureHandler: ((Reason, String?) -> Void)?, completion: Bool -> Void) {
    let parse: JSONDictionary -> Bool = { data in
        return true
    }
    
    let resource = authJsonResource(path: "/favorites/\(id)", method: .DELETE, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}


// MARK: - Teacher
///  获取老师详情数据
///
///  - parameter id:             老师id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func loadTeacherDetailData(id: Int, failureHandler: ((Reason, String?) -> Void)?, completion: TeacherDetailModel? -> Void) {
    
    let parse: JSONDictionary -> TeacherDetailModel? = { data in
        let model: TeacherDetailModel?
        model = TeacherDetailModel(dict: data)
        return model
    }
    
    var resource: Resource<TeacherDetailModel>?
    
    if MalaUserDefaults.isLogined {
        resource = authJsonResource(path: "/teachers/\(id)", method: .GET, requestParameters: nullDictionary(), parse: parse)
    }else {
        resource = jsonResource(path: "/teachers/\(id)", method: .GET, requestParameters: nullDictionary(), parse: parse)
    }
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource!, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource!, failure: defaultFailureHandler, completion: completion)
    }
}
///  获取[指定老师]在[指定上课地点]的可用时间表
///
///  - parameter teacherID:      老师id
///  - parameter schoolID:       上课地点id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getTeacherAvailableTimeInSchool(teacherID: Int, schoolID: Int, failureHandler: ((Reason, String?) -> Void)?, completion: [[ClassScheduleDayModel]] -> Void) {
    
    let requestParameters = [
        "school_id": schoolID,
    ]
    
    let parse: JSONDictionary -> [[ClassScheduleDayModel]] = { data in
        return parseClassSchedule(data)
    }
    
    let resource = authJsonResource(path: "teachers/\(teacherID)/weeklytimeslots", method: .GET, requestParameters: requestParameters, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}
///  获取[指定老师]在[指定上课地点]的价格阶梯
///
///  - parameter teacherID:      老师id
///  - parameter schoolID:       上课地点id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getTeacherGradePrice(teacherId: Int, schoolId: Int, failureHandler: ((Reason, String?) -> Void)?, completion: [GradeModel] -> Void) {
    
    let parse: JSONDictionary -> [GradeModel] = { data in
        return parseTeacherGradePrice(data)
    }
    
    let resource = authJsonResource(path: "teacher/\(teacherId)/school/\(schoolId)/price", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}
func loadTeachersWithConditions(conditions: JSONDictionary?, failureHandler: ((Reason, String?) -> Void)?, completion: [TeacherModel] -> Void) {
    
}


// MARK: - Course
///  获取课程信息
///
///  - parameter id:             课程id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getCourseInfo(id: Int, failureHandler: ((Reason, String?) -> Void)?, completion: CourseModel -> Void) {
    
    let parse: JSONDictionary -> CourseModel? = { data in
        return parseCourseInfo(data)
    }
    
    let resource = authJsonResource(path: "timeslots/\(id)", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取上课时间表
///
///  - parameter teacherID:      老师id
///  - parameter hours:          课时
///  - parameter timeSlots:      所选上课时间
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getConcreteTimeslots(teacherID: Int, hours: Int, timeSlots: [Int], failureHandler: ((Reason, String?) -> Void)?, completion: [[NSTimeInterval]]? -> Void) {
    
    guard timeSlots.count != 0 else {
        ThemeHUD.hideActivityIndicator()
        return
    }
    
    let timeSlotStrings = timeSlots.map { (id) -> String in
        return String(id)
    }
    
    let requestParameters = [
        "teacher": teacherID,
        "hours": hours,
        "weekly_time_slots": timeSlotStrings.joinWithSeparator(" ")
        ]
    
    let parse: JSONDictionary -> [[NSTimeInterval]]? = { data in
        return parseConcreteTimeslot(data)
    }
    
    let resource = authJsonResource(path: "concrete/timeslots", method: .GET, requestParameters: (requestParameters as! JSONDictionary), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}


// MARK: - Comment
///  创建评价
///
///  - parameter comment:        评价对象
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func createComment(comment: CommentModel, failureHandler: ((Reason, String?) -> Void)?, completion: Bool -> Void) {
    
    let requestParameters = [
        "timeslot": comment.timeslot,
        "score": comment.score,
        "content": comment.content
    ]
    
    let parse: JSONDictionary -> Bool = { data in
        return (data != nil)
    }
    
    let resource = authJsonResource(path: "comments", method: .POST, requestParameters: (requestParameters as! JSONDictionary), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取评价信息
///
///  - parameter id:             评价id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getCommentInfo(id: Int, failureHandler: ((Reason, String?) -> Void)?, completion: CommentModel -> Void) {
    
    let parse: JSONDictionary -> CommentModel? = { data in
        return parseCommentInfo(data)
    }
    
    let resource = authJsonResource(path: "comments/\(id)", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}


// MARK: - Payment
///  创建订单
///
///  - parameter orderForm:      订单对象字典
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func createOrderWithForm(orderForm: JSONDictionary, failureHandler: ((Reason, String?) -> Void)?, completion: OrderForm -> Void) {
    // teacher              老师id
    // school               上课地点id
    // grade                年级(&价格)id
    // subject              学科id
    // coupon               优惠卡券id
    // hours                用户所选课时数
    // weekly_time_slots    用户所选上课时间id数组
    
    /// 返回值解析器
    let parse: JSONDictionary -> OrderForm? = { data in
        return parseOrderCreateResult(data)
    }
    
    let resource = authJsonResource(path: "/orders", method: .POST, requestParameters: orderForm, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取支付信息
///
///  - parameter channel:        支付方式
///  - parameter orderID:        订单id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getChargeTokenWithChannel(channel: MalaPaymentChannel, orderID: Int, failureHandler: ((Reason, String?) -> Void)?, completion: JSONDictionary? -> Void) {
    let requestParameters = [
        "action": PaymentMethod.Pay.rawValue,
        "channel": channel.rawValue
    ]
    
    let parse: JSONDictionary -> JSONDictionary? = { data in
        return parseChargeToken(data)
    }
    
    let resource = authJsonResource(path: "/orders/\(orderID)", method: .PATCH, requestParameters: requestParameters, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取订单信息
///
///  - parameter orderID:        订单id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getOrderInfo(orderID: Int, failureHandler: ((Reason, String?) -> Void)?, completion: OrderForm -> Void) {
    /// 返回值解析器
    let parse: JSONDictionary -> OrderForm? = { data in
        return parseOrderFormInfo(data)
    }
    
    let resource = authJsonResource(path: "/orders/\(orderID)", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  取消订单
///
///  - parameter orderID:        订单id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func cancelOrderWithId(orderID: Int, failureHandler: ((Reason, String?) -> Void)?, completion: Bool -> Void) {
    /// 返回值解析器
    let parse: JSONDictionary -> Bool = { data in
        if let result = data["ok"] as? Bool {
            return result
        }
        return false
    }
    
    let resource = authJsonResource(path: "/orders/\(orderID)", method: .DELETE, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}


// MARK: - Study Report
///  获取学习报告总览
///  包括每个已报名学科，及其支持情况、答题数、正确数
///
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getStudyReportOverview(failureHandler: ((Reason, String?) -> Void)?, completion: [SimpleReportResultModel] -> Void) {
    /// 返回值解析器
    let parse: JSONDictionary -> [SimpleReportResultModel] = { data in
        return parseStudyReportResult(data)
    }
    
    let resource = authJsonResource(path: "/study_report", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取单个学科的学习报告
///
///  - parameter id: 学科id
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getSubjectReport(id: Int, failureHandler: ((Reason, String?) -> Void)?, completion: SubjectReport -> Void) {
    /// 返回值解析器
    let parse: JSONDictionary -> SubjectReport = { data in
        return parseStudyReport(data)
    }
    
    let resource = authJsonResource(path: "/study_report/\(id)", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}


// MARK: - Other
///  获取城市数据列表
///
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func loadRegions(failureHandler: ((Reason, String?) -> Void)?, completion: [BaseObjectModel] -> Void) {
    let parse: JSONDictionary -> [BaseObjectModel] = { data in
        return parseCitiesResult(data)
    }
    
    let resource = jsonResource(path: "/regions", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取学校数据列表
///
///  - parameter region: 城市id（传入即为筛选指定城市学校列表，为空则使用当前选择的城市id）
///  - parameter teacher: 老师id（传入即为筛选该老师指定的上课地点）
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getSchools(cityId: Int? = nil, teacher: Int? = nil, failureHandler: ((Reason, String?) -> Void)?, completion: [SchoolModel] -> Void) {
    
    let parse: JSONDictionary -> [SchoolModel] = { data in
        return sortSchoolsByDistance(parseSchoolsResult(data))
    }
    
    var params = nullDictionary()
    
    if let id = cityId {
        params["region"] = id
    } else if let region = MalaCurrentCity {
        params["region"] = region.id
    }
    if let teacherId = teacher {
        params["teacher"] = teacherId
    }
    
    let resource = authJsonResource(path: "/schools", method: .GET, requestParameters: params, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

///  获取用户协议HTML
///
///  - parameter failureHandler: 失败处理闭包
///  - parameter completion:     成功处理闭包
func getUserProtocolHTML(failureHandler: ((Reason, String?) -> Void)?, completion: String? -> Void) {
    
    let parse: JSONDictionary -> String? = { data in
        return parseUserProtocolHTML(data)
    }
    
    let resource = authJsonResource(path: "/policy", method: .GET, requestParameters: nullDictionary(), parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: MalaBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}



// MARK: - Parse
/// 订单JSON解析器
let parseOrderForm: JSONDictionary -> OrderForm? = { orderInfo in
    
    // 订单创建失败
    if let
        result = orderInfo["ok"] as? Bool,
        errorCode = orderInfo["code"] as? Int {
        return OrderForm(result: result, code: errorCode)
    }
    
    // 订单创建成功
    if let
        id          = orderInfo["id"] as? Int,
        teacher     = orderInfo["teacher"] as? Int,
        teacherName = orderInfo["teacher_name"] as? String,
        avatar      = orderInfo["teacher_avatar"] as? String,
        school      = orderInfo["school"] as? String,
        grade       = orderInfo["grade"] as? String,
        subject     = orderInfo["subject"] as? String,
        hours       = orderInfo["hours"] as? Int,
        status      = orderInfo["status"] as? String,
        orderId     = orderInfo["order_id"] as? String,
        amount      = orderInfo["to_pay"] as? Int,
        evaluated   = orderInfo["evaluated"] as? Bool {
        return OrderForm(id: id, orderId: orderId, teacherId: teacher, teacherName: teacherName, avatarURL: avatar, schoolName: school, gradeName: grade, subjectName: subject, orderStatus: status, amount: amount, evaluated: evaluated)
    }
    return nil
}
/// 订单JSON解析器
let parseOrderFormInfo: JSONDictionary -> OrderForm? = { orderInfo in
    
    // 订单创建失败
    if let
        result = orderInfo["ok"] as? Bool,
        errorCode = orderInfo["code"] as? Int {
        return OrderForm(result: result, code: errorCode)
    }
    
    // 订单创建成功
    if let
        id              = orderInfo["id"] as? Int,
        teacher         = orderInfo["teacher"] as? Int,
        teacherName     = orderInfo["teacher_name"] as? String,
        avatar          = orderInfo["teacher_avatar"] as? String,
        school          = orderInfo["school"] as? String,
        schoolId        = orderInfo["school_id"] as? Int,
        grade           = orderInfo["grade"] as? String,
        subject         = orderInfo["subject"] as? String,
        hours           = orderInfo["hours"] as? Int,
        status          = orderInfo["status"] as? String,
        orderId         = orderInfo["order_id"] as? String,
        amount          = orderInfo["to_pay"] as? Int,
        createdAt       = orderInfo["created_at"] as? NSTimeInterval,
        timeSlots       = orderInfo["timeslots"] as? [[NSTimeInterval]],
        evaluated       = orderInfo["evaluated"] as? Bool,
        isTimeAllocated = orderInfo["is_timeslot_allocated"] as? Bool,
        isteacherPublished = orderInfo["is_teacher_published"] as? Bool {
        // 订单信息
        let order = OrderForm(id: id, orderId: orderId, teacherId: teacher, teacherName: teacherName, avatarURL: avatar, schoolId: schoolId, schoolName: school, gradeName: grade, subjectName: subject, orderStatus: status, hours: hours, amount: amount, timeSlots: timeSlots, createAt: createdAt, evaluated: evaluated, teacherPublished: isteacherPublished)
        // 判断是否存在支付时间（未支付状态无此数据）
        if let paidAt = orderInfo["paid_at"] as? NSTimeInterval {
            order.paidAt = paidAt
        }
        // 判断是否存在支付渠道（订单取消状态无此数据）
        if let chargeChannel   = orderInfo["charge_channel"] as? String {
            order.chargeChannel = chargeChannel
        }
        
        return order
    }
    return nil
}
/// 订单创建返回结果JSON解析器
let parseOrderCreateResult: JSONDictionary -> OrderForm? = { orderInfo in
    
    println("结果：\(orderInfo)")
    
    // 订单创建失败
    if let
        result = orderInfo["ok"] as? Bool,
        errorCode = orderInfo["code"] as? Int {
        return OrderForm(result: result, code: errorCode)
    }
    
    // 订单创建成功
    if let
        id = orderInfo["id"] as? Int,
        amount = orderInfo["to_pay"] as? Int {
        let order = OrderForm()
        order.id = id
        order.amount = amount
        return order
    }
    return nil
}
/// SMS验证结果JSON解析器
let parseLoginUser: JSONDictionary -> LoginUser? = { userInfo in
    /// 判断验证结果是否正确
    guard let verified = userInfo["verified"] where (verified as? Bool) == true else {
        return nil
    }
    
    if let
        firstLogin = userInfo["first_login"] as? Bool,
        accessToken = userInfo["token"] as? String,
        parentID = userInfo["parent_id"] as? Int,
        userID = userInfo["user_id"] as? Int,
        profileID = userInfo["profile_id"] as? Int {
            return LoginUser(accessToken: accessToken, userID: userID, parentID: parentID, profileID: profileID, firstLogin: firstLogin, avatarURLString: "")
    }
    return nil
}
/// 个人信息JSON解析器
let parseProfile: JSONDictionary -> profileInfo? = { profileData in
    /// 判断验证结果是否正确
    guard let profileID = profileData["id"] else {
        return nil
    }
    
    if let
        id = profileData["id"] as? Int,
        gender = profileData["gender"] as? String? {
            let avatar = (profileData["avatar"] as? String) ?? ""
            return profileInfo(id: id, gender: gender, avatar: avatar)
    }
    return nil
}
/// 家长信息JSON解析器
let parseParent: JSONDictionary -> parentInfo? = { parentData in
    /// 判断验证结果是否正确
    guard let parentID = parentData["id"] else {
        return nil
    }
    
    if let
        id = parentData["id"] as? Int,
        studentName = parentData["student_name"] as? String?,
        schoolName = parentData["student_school_name"] as? String? {
            return parentInfo(id: id, studentName: studentName, schoolName: schoolName)
    }
    return nil
}
/// 优惠券JSON解析器
let parseCoupon: JSONDictionary -> CouponModel? = { couponInfo in

    /// 检测返回值有效性
    guard let id = couponInfo["id"] else {
        return nil
    }
    
    if let
        id = couponInfo["id"] as? Int,
        name = couponInfo["name"] as? String,
        amount = couponInfo["amount"] as? Int,
        expired_at = couponInfo["expired_at"] as? NSTimeInterval,
        minPrice = couponInfo["mini_total_price"] as? Int,
        used = couponInfo["used"] as? Bool {
        return CouponModel(id: id, name: name, amount: amount, expired_at: expired_at, minPrice: minPrice, used: used)
    }
    return nil
}
/// 可用上课时间表JSON解析器
let parseClassSchedule: JSONDictionary -> [[ClassScheduleDayModel]] = { scheduleInfo in
    
    // 本周时间表
    var weekSchedule: [[ClassScheduleDayModel]] = []
    
    // 循环一周七天的可用时间表
    for index in 1...7 {
        if let day = scheduleInfo[String(index)] as? [[String: AnyObject]] {
            var daySchedule: [ClassScheduleDayModel] = []
            for dict in day {
                daySchedule.append(ClassScheduleDayModel(dict: dict))
            }
            weekSchedule.append(daySchedule)
        }
    }
    return weekSchedule
}
/// 学生上课时间表JSON解析器
let parseStudentCourse: JSONDictionary -> [StudentCourseModel] = { courseInfos in
    
    /// 学生上课时间数组
    var courseList: [StudentCourseModel] = []
    
    /// 确保相应格式正确，且存在数据
    guard let courses = courseInfos["results"] as? [JSONDictionary] where courses.count != 0 else {
        return courseList
    }
    
    ///  遍历字典数组，转换为模型
    for course in courses {

        if let
            id = course["id"] as? Int,
            start = course["start"] as? NSTimeInterval,
            end = course["end"] as? NSTimeInterval,
            subject = course["subject"] as? String,
            grade = course["grade"] as? String,
            school = course["school"] as? String,
            is_passed = course["is_passed"] as? Bool,
            is_expired = course["is_expired"] as? Bool {
            
            let model = StudentCourseModel(id: id, start: start, end: end, subject: subject, grade: grade, school: school, is_passed: is_passed, is_expired: is_expired)
            
            if let is_commented = course["is_commented"] as? Bool {
                model.is_commented = is_commented
            }
            
            /// 老师模型
            if let
                teacherDict = course["teacher"] as? JSONDictionary,
                id = teacherDict["id"] as? Int,
                avatar = teacherDict["avatar"] as? String,
                name = teacherDict["name"] as? String {
                model.teacher = TeacherModel(id: id, name: name, avatar: avatar)
            }
            /// 评价模型
            if let
                commentDict = course["comment"] as? JSONDictionary,
                id = commentDict["id"] as? Int,
                timeslot = commentDict["timeslot"] as? Int,
                score = commentDict["score"] as? Int,
                content = commentDict["content"] as? String {
                model.comment = CommentModel(id: id, timeslot: timeslot, score: score, content: content)
            }
            
            courseList.append(model)
        }else {
            continue
        }
    }
    return courseList
}
/// 课程信息JSON解析器
let parseCourseInfo: JSONDictionary -> CourseModel? = { courseInfo in
    
    guard let id = courseInfo["id"] as? Int else {
        return nil
    }
    
    if let
        id = courseInfo["id"] as? Int,
        start = courseInfo["start"] as? NSTimeInterval,
        end = courseInfo["end"] as? NSTimeInterval,
        subject = courseInfo["subject"] as? String,
        school = courseInfo["school"] as? String,
        is_passed = courseInfo["is_passed"] as? Bool,
        teacher = courseInfo["teacher"] as? JSONDictionary {
            return CourseModel(dict: courseInfo)
    }
    return nil
}
/// 评论信息JSON解析器
let parseCommentInfo: JSONDictionary -> CommentModel? = { commentInfo in
    
    guard let id = commentInfo["id"] as? Int else {
        return nil
    }
    
    if let
        id = commentInfo["id"] as? Int,
        timeslot = commentInfo["timeslot"] as? Int,
        score = commentInfo["score"] as? Int,
        content = commentInfo["content"] as? String {
            return CommentModel(dict: commentInfo)
    }
    return nil
}
/// 用户协议JSON解析器
let parseUserProtocolHTML: JSONDictionary -> String? = { htmlInfo in
    
    guard let updatedAt = htmlInfo["updated_at"] as? Int, htmlString = htmlInfo["content"] as? String else {
        return nil
    }

    return htmlString
}
/// 上课时间表JSON解析器
let parseConcreteTimeslot: JSONDictionary -> [[NSTimeInterval]]? = { timeSlotsInfo in
    
    guard let data = timeSlotsInfo["data"] as? [[NSTimeInterval]] where data.count != 0 else {
        return nil
    }
    
    return data
}
/// 订单列表JSON解析器
let parseOrderList: JSONDictionary -> ([OrderForm], Int) = { ordersInfo in
    
    var orderList: [OrderForm] = []
    
    guard let orders = ordersInfo["results"] as? [JSONDictionary], count = ordersInfo["count"] as? Int where count != 0 else {
        return (orderList, 0)
    }
    
    for order in orders {
        if let
            id          = order["id"] as? Int,
            teacher     = order["teacher"] as? Int,
            teacherName = order["teacher_name"] as? String,
            avatar      = order["teacher_avatar"] as? String,
            school      = order["school"] as? String,
            grade       = order["grade"] as? String,
            subject     = order["subject"] as? String,
            hours       = order["hours"] as? Int,
            status      = order["status"] as? String,
            orderId     = order["order_id"] as? String,
            amount      = order["to_pay"] as? Int,
            evaluated   = order["evaluated"] as? Bool,
            isteacherPublished = order["is_teacher_published"] as? Bool {
            orderList.append(OrderForm(id: id, orderId: orderId, teacherId: teacher, teacherName: teacherName, avatarURL: avatar, schoolName: school, gradeName: grade, subjectName: subject, orderStatus: status, amount: amount, evaluated: evaluated, teacherPublished: isteacherPublished))
        }
    }
    
    return (orderList, count)
}
/// 支付信息JSON解析器
let parseChargeToken: JSONDictionary -> JSONDictionary? = { chargeInfo in
    
    // 支付信息获取失败（课程被占用）
    if let
        result = chargeInfo["ok"] as? Bool,
        errorCode = chargeInfo["code"] as? Int {
        return ["result": result]
    }
    
    // 支付信息获取成功
    return chargeInfo
}
/// 学习报告总览JSON解析器
let parseStudyReportResult: JSONDictionary -> [SimpleReportResultModel] = { resultInfo in
    
    var reports = [SimpleReportResultModel]()
    
    if let results = resultInfo["results"] as? [JSONDictionary] {
        for report in results {
            reports.append(SimpleReportResultModel(dict: report))
        }
    }
    return reports
}
/// 单门学习报告数据JSON解析器
let parseStudyReport: JSONDictionary -> SubjectReport = { reportInfo in
    var report = SubjectReport(dict: reportInfo)
    return report
}
/// 学校数据列表JSON解析器
let parseSchoolsResult: JSONDictionary -> [SchoolModel] = { resultInfo in
    
    var schools: [SchoolModel] = []
    
    if let results = resultInfo["results"] as? [JSONDictionary] where results.count > 0 {
        for school in results {
            schools.append(SchoolModel(dict: school))
        }
    }
    return schools
}
/// 老师收藏列表JSON解析器
let parseFavoriteTeacherResult: JSONDictionary -> ([TeacherModel], Int) = { resultInfo in
    
    var teachers: [TeacherModel] = []
    var count = 0
    
    if let allCount = resultInfo["count"] as? Int, results = resultInfo["results"] as? [JSONDictionary] where results.count > 0 {
        count = allCount
        for teacher in results {
            teachers.append(TeacherModel(dict: teacher))
        }
    }
    return (teachers, count)
}
/// 城市数据列表JSON解析器
let parseCitiesResult: JSONDictionary -> [BaseObjectModel] = { resultInfo in
    
    var cities: [BaseObjectModel] = []
    
    if let results = resultInfo["results"] as? [JSONDictionary] where results.count > 0 {
        for school in results {
            cities.append(BaseObjectModel(dict: school))
        }
    }
    return cities
}
/// 价格阶梯JSON解析器
let parseTeacherGradePrice: JSONDictionary -> [GradeModel] = { resultInfo in
    
    var prices: [GradeModel] = []

    if let results = info["results"] as? [JSONDictionary] where results.count > 0 {
        for grade in results {
            prices.append(GradeModel(dict: grade))
        }
    }
    return prices
}
