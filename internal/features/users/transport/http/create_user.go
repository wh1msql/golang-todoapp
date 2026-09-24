package users_transport_http

import (
	"net/http"

	"github.com/wh1msql/golang-todoapp/internal/core/domain"
	core_logger "github.com/wh1msql/golang-todoapp/internal/core/logger"
	core_http_request "github.com/wh1msql/golang-todoapp/internal/core/transport/http/request"
	core_http_response "github.com/wh1msql/golang-todoapp/internal/core/transport/http/response"
)

type CreateUserRequest struct {
	FullName    string  `json:"full_name" validate:"required,min=2,max=255"`
	PhoneNumber *string `json:"phone_number" validate:"omitempty,min=10,max=15,startswith=+"`
}

type CreateUserResponse UserDTOResponse

func (h *UsersHTTPHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	log := core_logger.FromContext(ctx)
	responseHandler := core_http_response.NewHTTPResponseHandler(log, w)

	log.Debug("invoke CreateUser handler")

	var request CreateUserRequest
	if err := core_http_request.DecodeAndValidateRequest(r, &request); err != nil {
		responseHandler.ErrorResponse(err, "failed to decode and validate HTTP request")

		return
	}

	userDomain := userDomainFromRequest(request)

	userDomain, err := h.usersService.CreateUser(ctx, userDomain)
	if err != nil {
		responseHandler.ErrorResponse(err, "failed to create user")

		return
	}

	response := CreateUserResponse(userDTOFromDomain(userDomain))

	responseHandler.JSONResponse(response, http.StatusCreated)
}

func userDomainFromRequest(request CreateUserRequest) domain.User {
	return domain.NewUserUninitialized(request.FullName, request.PhoneNumber)
}
