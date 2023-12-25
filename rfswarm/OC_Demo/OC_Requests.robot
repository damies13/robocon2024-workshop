*** Settings ***
Library 	RequestsLibrary
Library		FakerLibrary

Resource    perftest.robot

*** Variables ***
${StoreHost} 	192.168.13.69
${StorePage} 	http://${StoreHost}
${AdminPage} 	${StorePage}/admin

# ${ThinkTime}	30
# ${ThinkTime}	15
# ${ThinkTime}	5
${ThinkTime}	1

${RFS_ROBOT}	1
${WaitTimout}		120


*** Test Cases ***
Opencart Sales
	Open Store
	Sleep    ${ThinkTime}
	${productPage}= 	Set Variable    False
	${items}= 	Evaluate 	random.randint(1, 5)
	FOR 	${i} 	IN RANGE 	${items}
		WHILE    not ${productPage}
			Open Random Page
			Sleep    ${ThinkTime}
			# id="button-cart"
			${productPage}= 	Run Keyword And Return Status 	Should Contain 	${LastResponse.text} 	id="button-cart"
		END
		Add To Cart
		Sleep    ${ThinkTime}
		${productPage}= 	Set Variable    False
	END
	Open Cart
	Sleep    ${ThinkTime}
	Checkout Step 1
	Sleep    ${ThinkTime}
	Checkout Step 2
	Sleep    ${ThinkTime}
	Checkout Step 3
	Sleep    ${ThinkTime}
	# Checkout Step 4
	# Sleep    ${ThinkTime}
	Checkout Step 5
	Sleep    ${ThinkTime}
	Checkout Step 6
	Sleep    ${ThinkTime}
	Confirm Order
	Sleep    ${ThinkTime}

*** Keywords ***
Get Resources
	[Arguments]		${Response}
	Log 	${Response.headers}
	Log 	${Response.text}
	Set Suite Variable    $LastResponse    ${Response}
	# 'Content-Type': 'text/html;
	${ishtml} = 	Run Keyword And Return Status 	Should Contain Any 	${Response.headers["Content-Type"]} 	text/html
	IF 	${ishtml}
		# <script src="catalog/view/javascript/jquery/jquery-2.1.1.min.js"
		${srcs}= 	Get Regexp Matches 	${Response.text} 	src="([^"?]*) 	1
		FOR 	${src} 	IN 	@{srcs}
			${isfullurl} = 	Run Keyword And Return Status 	Should Contain Any 	${src} 	//
			IF	${isfullurl}
				IF	'${src}[1]' == '/'
					GET On Session 	OpenCart 	https:${src}
				ELSE
					GET On Session 	OpenCart 	${src}
				END
			ELSE
				GET On Session 	OpenCart 	${src}
			END
		END

		${hrefs}= 	Get Regexp Matches 	${Response.text} 	[^(?!.<a.<base)] href="([^"]*) 	1
		FOR 	${href} 	IN 	@{hrefs}
			${isfullurl} = 	Run Keyword And Return Status 	Should Contain Any 	${href} 	//
			IF	${isfullurl}
				IF	'${href}[1]' == '/'
					GET On Session 	OpenCart 	https:${href}
				ELSE
					GET On Session 	OpenCart 	${href}
				END
			ELSE
				GET On Session 	OpenCart 	${href}
			END
		END
	END

Open Store
	[Documentation]		Open Store (Requests)
	Create Session 	OpenCart 	${StorePage} 	verify=False 	disable_warnings=1
	${hdrs}= 	Create Dictionary    User-Agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36
	Update Session 	OpenCart 	headers=${hdrs}
	${resp}= 	GET on Session 	OpenCart 	/
	${hdrs}= 	Create Dictionary    Referer=https://${StoreHost}/
	Update Session 	OpenCart 	headers=${hdrs}
	Get Resources 	${resp}

Is Link OK
	[Arguments]		${link}
	${badurl}= 	Run Keyword And Return Status 	Should Not Contain 	${link} 	${StoreHost}
	IF	${badurl}
		RETURN 	False
	END
	${badurl}= 	Run Keyword And Return Status 	Should Contain 	${link} 	route
	IF	${badurl}
		RETURN 	False
	END
	${badurl}= 	Run Keyword And Return Status 	Should Contain 	${link} 	image
	IF	${badurl}
		RETURN 	False
	END
	RETURN 	True

Open Random Page
	[Documentation]		Open Random Page (Requests)
	${links}= 	Get Regexp Matches 	${LastResponse.text} 	<a[^>]*href="([^"]*) 	1
	${count}= 	Get Length 	${links}
	${random}= 	Evaluate 	random.randint(0, ${count-1})
	${link}=		Set Variable    ${links}[${random}]
	${LinkOK}= 	Is Link OK 	${link}
	WHILE 	not ${LinkOK}
		${random}= 	Evaluate 	random.randint(0, ${count-1})
		${link}=		Set Variable    ${links}[${random}]
		${LinkOK}= 	Is Link OK 	${link}
	END
	${resp}= 	GET on Session 	OpenCart 	${link}
	Get Resources 	${resp}

Add To Cart
	[Documentation]		Add Item To Cart (Requests)
	# <input type="text" name="quantity" value="1" size="2" id="input-quantity" class="form-control" />
	# <input type="hidden" name="product_id" value="43" />
	# <br />
	# <button type="button" id="button-cart" data-loading-text="Loading..." class="btn btn-primary btn-lg btn-block">Add to Cart</button>
	${productid}= 	Get Regexp Matches 	${LastResponse.text} 	name="product_id"[^>]*value="([^"]*)  	1
	${quantity}= 		Get Regexp Matches 	${LastResponse.text} 	name="quantity"[^>]*value="([^"]*)  	1
	${quantity}= 	Evaluate 	random.randint(1, 3)

	Set Suite Variable    $PrevResponse    ${LastResponse}
	# POST 	https://192.168.13.66/index.php?route=checkout/cart/add 	quantity=13&product_id=43
	${data}=	Create Dictionary    quantity=${quantity} 	product_id=${productid}[0]
	# ${resp}= 	POST On Session 	OpenCart 	url=/index.php?route=checkout/cart/add 	data=${data}
	${resp}= 	POST On Session 	OpenCart 	url=/index.php?route=checkout/cart.add&language=en-gb 	data=${data}

	# GET 	https://192.168.13.66/index.php?route=common/cart/info
	# ${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=common/cart/info
	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=common/cart.info
	Get Resources 	${resp}
	Set Suite Variable    $LastResponse    ${PrevResponse}

Open Cart
	[Documentation]		Open Cart (Requests)
	# http://192.168.13.66/index.php?route=checkout/cart
	# ${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/cart
	${resp}= 	GET on Session 	OpenCart 	url=/en-gb?route=checkout/cart
	${hdrs}= 	Create Dictionary    Referer=https://${StoreHost}/en-gb?route=checkout/cart
	Update Session 	OpenCart 	headers=${hdrs}
	Get Resources 	${resp}

Checkout Step 1
	[Documentation]		Checkout - Checkout Options (Step 1) (Requests)
	# ${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/checkout
	${resp}= 	GET on Session 	OpenCart 	url=/en-gb?route=checkout/checkout
	# ${hdrs}= 	Create Dictionary    Referer=https://${StoreHost}/index.php?route=checkout/checkout
	${hdrs}= 	Create Dictionary    Referer=https://${StoreHost}/en-gb?route=checkout/checkout
	Update Session 	OpenCart 	headers=${hdrs}
	Get Resources 	${resp}
	# ${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/login

Checkout Step 2
	[Documentation]		Checkout - Billing Details (Step 2) (Requests)
	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/guest
	Get Resources 	${resp}
	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/checkout/customfield&customer_group_id=1
	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/checkout/country&country_id=222

Checkout Step 3
	[Documentation]		Checkout - Delivery Details (Step 3) (Requests)
	${fname}= 	First Name
	${lname}= 	Last Name
	${email}= 	Email
	${phone}= 	Phone Number
	${addr}= 	Street Address
	${city}= 	City
	${postcode}= 	Postcode

	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/checkout/country&country_id=223
	# zone_id"[^"]*"([^"]*)
	${zone_ids}= 	Get Regexp Matches 	${resp.text} 	zone_id"[^"]*"([^"]*)  	1
	${count}= 	Get Length 	${zone_ids}
	${random}= 	Evaluate 	random.randint(0, ${count-1})
	${zone_id}=		Set Variable    ${zone_ids}[${random}]
	# customer_group_id=1&firstname=a&lastname=b&email=c%40c.co&telephone=123456789&company=&address_1=12+some
	# 		&address_2=&city=city&postcode=1234&country_id=223&zone_id=3626&shipping_address=1
	${data}=	Create Dictionary    customer_group_id=1 	firstname=${fname} 	lastname=${lname} 	email=${email}
	... 	telephone=${phone} 	company= 	address_1=${addr} 	address_2= 	city=${city} 	postcode=${postcode}
	...		country_id=${223} 	zone_id=${zone_id} 	shipping_address=1
	# POST 		/index.php?route=checkout/guest/save
	${resp}= 	POST On Session 	OpenCart 	url=/index.php?route=checkout/guest/save 	data=${data}
	Get Resources 	${resp}

	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/shipping_method
	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/guest_shipping
	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/checkout/country&country_id=223

# # Checkout Step 4
# 	[Documentation]		Checkout - Delivery Method (Step 4)
Checkout Step 5
	[Documentation]		Checkout - Payment Method (Step 5) (Requests)
	# shipping_method=flat.flat&comment=
	${data}=	Create Dictionary    shipping_method=flat.flat 	comment=
	# Request URL:https://192.168.13.66/index.php?route=checkout/shipping_method/save
	# Request Method:POST
	${resp}= 	POST On Session 	OpenCart 	url=/index.php?route=checkout/shipping_method/save 	data=${data}
	Get Resources 	${resp}
	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/payment_method

Checkout Step 6
	[Documentation]		Checkout - Confirm Order (Step 6) (Requests)
	# payment_method=cod&comment=&agree=1
	${data}=	Create Dictionary    payment_method=cod 	comment= 	agree=1
	# Request URL:https://192.168.13.66/index.php?route=checkout/payment_method/save
	# Request Method:POST
	${resp}= 	POST On Session 	OpenCart 	url=/index.php?route=checkout/payment_method/save 	data=${data}
	Get Resources 	${resp}
	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/confirm

Confirm Order
	[Documentation]		Confirm Order (Requests)
	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=extension/payment/cod/confirm
	${resp}= 	GET on Session 	OpenCart 	url=/index.php?route=checkout/success
	Get Resources 	${resp}


#
